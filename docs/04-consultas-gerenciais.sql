-- ============================================================================
-- Meneghini Odontologia Integrada: banco de dados do trabalho
-- Arquivo 4 de 5: consultas gerenciais (G01 a G14)
-- Rodar depois de 03-manipulacao.sql.
--
-- Cada consulta responde a um problema da clínica (P1 a P5, README Seção 1)
-- ou calcula um indicador da Seção 14 (BI e IA). O cabeçalho de cada uma
-- diz a pergunta e o que ela atende. Todas devolvem linhas com a massa do
-- arquivo 2.
--
-- Problemas (README, Seção 1):
--   P1 informação do paciente espalhada (sem histórico único)
--   P2 pedido ao laboratório sem registro e sem prazo
--   P3 orçamento aprovado em parte, sem controle do que foi feito
--   P4 inadimplência sem bloqueio automático do agendamento
--   P5 retorno depois da alta sem controle
-- ============================================================================
USE meneghini_odontologia;

-- G01 — Qual é o histórico completo de um paciente: consultas, dentista, procedimentos e evolução?
-- Atende: P1 (informação espalhada). Exemplo com o paciente 2.
SELECT P.NM_PACIENTE                                         AS paciente,
       A.DT_HORA_INICIO                                      AS data_hora,
       A.TP_AGENDAMENTO                                      AS tipo,
       A.CD_STATUS                                           AS situacao,
       C.NM_COLABORADOR                                      AS dentista,
       GROUP_CONCAT(DISTINCT PR.NM_PROCEDIMENTO ORDER BY PR.NM_PROCEDIMENTO SEPARATOR '; ') AS procedimentos,
       E.DS_EVOLUCAO                                         AS evolucao,
       E.DS_PROXIMOS_PASSOS                                  AS proximos_passos
FROM PACIENTE P
JOIN AGENDAMENTO A            ON A.ID_PACIENTE = P.ID_PACIENTE
JOIN COLABORADOR C            ON C.ID_COLABORADOR = A.ID_COLABORADOR
LEFT JOIN AGENDAMENTO_ITEM AI ON AI.ID_AGENDAMENTO = A.ID_AGENDAMENTO
LEFT JOIN ITEM_ORCAMENTO I    ON I.ID_ORCAMENTO = AI.ID_ORCAMENTO AND I.NR_ITEM = AI.NR_ITEM
LEFT JOIN PROCEDIMENTO PR     ON PR.ID_PROCEDIMENTO = I.ID_PROCEDIMENTO
LEFT JOIN EVOLUCAO_CLINICA E  ON E.ID_AGENDAMENTO = A.ID_AGENDAMENTO
WHERE P.ID_PACIENTE = 2
GROUP BY P.NM_PACIENTE, A.ID_AGENDAMENTO, A.DT_HORA_INICIO, A.TP_AGENDAMENTO, A.CD_STATUS,
         C.NM_COLABORADOR, E.DS_EVOLUCAO, E.DS_PROXIMOS_PASSOS
ORDER BY A.DT_HORA_INICIO;

-- G02 — Quanto cada paciente contratou, já pagou, ainda vai pagar e está devendo?
-- Atende: P4 (inadimplência) e o KPI de inadimplência da Seção 14.
SELECT P.ID_PACIENTE,
       P.NM_PACIENTE                                                    AS paciente,
       CT.ID_CONTRATO                                                   AS contrato,
       CT.TP_FORMA_PAGAMENTO                                            AS forma,
       CT.VL_CONTRATADO                                                 AS contratado,
       IFNULL(CT.VL_ENTRADA, 0)                                         AS entrada,
       SUM(CASE WHEN PA.CD_STATUS = 'paga' THEN PA.VL_PARCELA ELSE 0 END) AS pago,
       SUM(CASE WHEN PA.CD_STATUS = 'aberta' AND PA.DT_VENCIMENTO >= CURDATE() THEN PA.VL_PARCELA ELSE 0 END) AS a_vencer,
       SUM(CASE WHEN PA.CD_STATUS = 'atrasada' OR (PA.CD_STATUS = 'aberta' AND PA.DT_VENCIMENTO < CURDATE()) THEN PA.VL_PARCELA ELSE 0 END) AS vencido,
       SUM(CASE WHEN PA.CD_STATUS = 'atrasada' THEN 1 ELSE 0 END)       AS parcelas_atrasadas
FROM CONTRATO CT
JOIN ORCAMENTO O ON O.ID_ORCAMENTO = CT.ID_ORCAMENTO
JOIN PACIENTE P  ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN PARCELA PA  ON PA.ID_CONTRATO = CT.ID_CONTRATO
GROUP BY P.ID_PACIENTE, P.NM_PACIENTE, CT.ID_CONTRATO, CT.TP_FORMA_PAGAMENTO, CT.VL_CONTRATADO, CT.VL_ENTRADA
ORDER BY vencido DESC, P.NM_PACIENTE;

-- G03 — Quais pacientes estão bloqueados por duas ou mais parcelas atrasadas, e quanto devem?
-- Atende: P4 (inadimplência) e a regra RN19 (bloqueio do agendamento).
SELECT P.ID_PACIENTE,
       P.NM_PACIENTE                        AS paciente,
       (SELECT GROUP_CONCAT(T.NR_TELEFONE SEPARATOR ' / ')
          FROM TELEFONE_PACIENTE T
         WHERE T.ID_PACIENTE = P.ID_PACIENTE) AS telefones,
       COUNT(*)                             AS parcelas_atrasadas,
       SUM(PA.VL_PARCELA)                   AS valor_atrasado,
       MIN(PA.DT_VENCIMENTO)                AS atraso_mais_antigo,
       DATEDIFF(CURDATE(), MIN(PA.DT_VENCIMENTO)) AS dias_de_atraso
FROM PARCELA PA
JOIN CONTRATO CT ON CT.ID_CONTRATO = PA.ID_CONTRATO
JOIN ORCAMENTO O ON O.ID_ORCAMENTO = CT.ID_ORCAMENTO
JOIN PACIENTE P  ON P.ID_PACIENTE = O.ID_PACIENTE
WHERE PA.CD_STATUS = 'atrasada'
GROUP BY P.ID_PACIENTE, P.NM_PACIENTE
HAVING COUNT(*) >= 2
ORDER BY valor_atrasado DESC;

-- G04 — O que ainda falta executar de cada plano aprovado (itens aprovados e em aberto)?
-- Atende: P3 (orçamento aprovado em parte, controle da execução item a item).
SELECT P.NM_PACIENTE                 AS paciente,
       O.ID_ORCAMENTO                AS orcamento,
       O.CD_STATUS                   AS situacao_orcamento,
       I.NR_ITEM                     AS item,
       PR.NM_PROCEDIMENTO            AS procedimento,
       I.NR_DENTE                    AS dente,
       I.TP_FASE                     AS fase,
       I.VL_NEGOCIADO                AS valor,
       MIN(A.DT_HORA_INICIO)         AS proxima_consulta_marcada
FROM ITEM_ORCAMENTO I
JOIN ORCAMENTO O              ON O.ID_ORCAMENTO = I.ID_ORCAMENTO
JOIN PACIENTE P               ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN PROCEDIMENTO PR          ON PR.ID_PROCEDIMENTO = I.ID_PROCEDIMENTO
LEFT JOIN AGENDAMENTO_ITEM AI ON AI.ID_ORCAMENTO = I.ID_ORCAMENTO AND AI.NR_ITEM = I.NR_ITEM
LEFT JOIN AGENDAMENTO A       ON A.ID_AGENDAMENTO = AI.ID_AGENDAMENTO
                             AND A.CD_STATUS IN ('agendado', 'confirmado')
WHERE I.CD_STATUS_APROVACAO = 'aprovado'
  AND I.CD_STATUS_EXECUCAO  = 'em_aberto'
GROUP BY P.NM_PACIENTE, O.ID_ORCAMENTO, O.CD_STATUS, I.NR_ITEM, PR.NM_PROCEDIMENTO,
         I.NR_DENTE, I.TP_FASE, I.VL_NEGOCIADO
ORDER BY P.NM_PACIENTE, O.ID_ORCAMENTO, I.NR_ITEM;

-- G05 — Quantos orçamentos foram emitidos por mês e quantos viraram contrato (taxa de conversão)?
-- Atende: P3 e o KPI de conversão da Seção 14. Período: agosto a novembro de 2026.
SELECT DATE_FORMAT(O.DT_EMISSAO, '%Y-%m')                                       AS mes,
       COUNT(*)                                                                 AS emitidos,
       SUM(O.CD_STATUS = 'aprovado')                                            AS aprovados,
       SUM(O.CD_STATUS = 'aprovado_parcial')                                    AS aprovados_em_parte,
       SUM(O.CD_STATUS = 'recusado')                                            AS recusados,
       SUM(O.CD_STATUS = 'em_negociacao')                                       AS em_negociacao,
       SUM(O.VL_TOTAL)                                                          AS valor_orcado,
       SUM(IFNULL(CT.VL_CONTRATADO, 0))                                         AS valor_contratado,
       ROUND(100 * SUM(CT.ID_CONTRATO IS NOT NULL) / COUNT(*), 1)               AS conversao_pct
FROM ORCAMENTO O
LEFT JOIN CONTRATO CT ON CT.ID_ORCAMENTO = O.ID_ORCAMENTO
WHERE O.DT_EMISSAO BETWEEN '2026-08-01' AND '2026-11-30'
GROUP BY DATE_FORMAT(O.DT_EMISSAO, '%Y-%m') WITH ROLLUP
ORDER BY mes;

-- G06 — Quais peças estão no laboratório, para quem, com que prazo, e quais já estouraram?
-- Atende: P2 (pedido ao laboratório sem registro e sem prazo).
SELECT L.ID_PEDIDO,
       P.NM_PACIENTE                                   AS paciente,
       C.NM_COLABORADOR                                AS dentista_solicitante,
       L.DS_PECA                                       AS peca,
       L.DT_SOLICITACAO                                AS solicitado_em,
       L.DT_PRAZO_ENTREGA                              AS prazo,
       L.CD_STATUS                                     AS situacao,
       DATEDIFF(L.DT_PRAZO_ENTREGA, CURDATE())         AS dias_para_o_prazo,
       CASE
           WHEN L.DT_PRAZO_ENTREGA < CURDATE() THEN 'ATRASADO'
           WHEN L.DT_PRAZO_ENTREGA <= CURDATE() + INTERVAL 3 DAY THEN 'vence em 3 dias'
           ELSE 'no prazo'
       END                                             AS alerta
FROM PEDIDO_LABORATORIO L
JOIN PACIENTE P    ON P.ID_PACIENTE = L.ID_PACIENTE
JOIN COLABORADOR C ON C.ID_COLABORADOR = L.ID_COLABORADOR
WHERE L.CD_STATUS <> 'entregue'
ORDER BY L.DT_PRAZO_ENTREGA;

-- G07 — Quais pacientes tiveram alta, quando é o retorno previsto e quem ainda não voltou?
-- Atende: P5 (retorno depois da alta) e o KPI de retorno da Seção 14.
SELECT P.ID_PACIENTE,
       P.NM_PACIENTE                      AS paciente,
       (SELECT GROUP_CONCAT(T.NR_TELEFONE SEPARATOR ' / ')
          FROM TELEFONE_PACIENTE T
         WHERE T.ID_PACIENTE = P.ID_PACIENTE) AS telefones,
       DATE(ALTA.DT_HORA_INICIO)          AS data_alta,
       ALTA.DT_RETORNO_PREVISTO           AS retorno_previsto,
       RET.DT_HORA_INICIO                 AS retorno_marcado,
       RET.CD_STATUS                      AS situacao_retorno,
       CASE
           WHEN RET.CD_STATUS = 'atendido'                                   THEN 'retorno realizado'
           WHEN RET.ID_AGENDAMENTO IS NOT NULL                               THEN 'retorno marcado'
           WHEN ALTA.DT_RETORNO_PREVISTO < CURDATE()                         THEN 'VENCIDO, ligar para o paciente'
           WHEN ALTA.DT_RETORNO_PREVISTO <= CURDATE() + INTERVAL 30 DAY      THEN 'vence em 30 dias'
           ELSE 'a vencer'
       END                                AS acao
FROM AGENDAMENTO ALTA
JOIN PACIENTE P          ON P.ID_PACIENTE = ALTA.ID_PACIENTE
LEFT JOIN AGENDAMENTO RET ON RET.ID_PACIENTE = ALTA.ID_PACIENTE
                         AND RET.TP_AGENDAMENTO = 'retorno'
                         AND RET.DT_HORA_INICIO > ALTA.DT_HORA_INICIO
WHERE ALTA.TP_AGENDAMENTO = 'alta'
  AND ALTA.CD_STATUS = 'atendido'
ORDER BY ALTA.DT_RETORNO_PREVISTO;

-- G08 — Quanto a clínica recebeu por mês (entradas de contrato + parcelas pagas)?
-- Atende: KPI de faturamento recebido da Seção 14. Período: 2026 inteiro, mês a mês.
SELECT R.mes,
       SUM(CASE WHEN R.tipo = 'entrada' THEN R.valor ELSE 0 END)   AS entradas,
       SUM(CASE WHEN R.tipo = 'parcela' THEN R.valor ELSE 0 END)   AS parcelas_pagas,
       SUM(R.valor)                                                AS recebido_no_mes
FROM (
    SELECT DATE_FORMAT(DT_ASSINATURA, '%Y-%m') AS mes, 'entrada' AS tipo, VL_ENTRADA AS valor
    FROM CONTRATO
    WHERE VL_ENTRADA IS NOT NULL
    UNION ALL
    SELECT DATE_FORMAT(DT_PAGAMENTO, '%Y-%m'), 'parcela', VL_PARCELA
    FROM PARCELA
    WHERE CD_STATUS = 'paga'
) R
WHERE R.mes BETWEEN '2026-01' AND '2026-12'
GROUP BY R.mes
ORDER BY R.mes;

-- G09 — Qual foi a ocupação de cada consultório em outubro de 2026?
-- Atende: KPI de ocupação da Seção 14. Outubro de 2026 tem 22 dias úteis; a clínica
-- atende 8 horas por dia, então cada consultório oferece 22 x 8 x 60 = 10.560 minutos.
SELECT S.NR_CONSULTORIO                                                  AS consultorio,
       COUNT(A.ID_AGENDAMENTO)                                           AS consultas_atendidas,
       IFNULL(SUM(A.QT_DURACAO_MIN), 0)                                  AS minutos_atendidos,
       10560                                                             AS minutos_disponiveis,
       ROUND(100 * IFNULL(SUM(A.QT_DURACAO_MIN), 0) / 10560, 1)          AS ocupacao_pct
FROM CONSULTORIO S
LEFT JOIN AGENDAMENTO A ON A.ID_CONSULTORIO = S.ID_CONSULTORIO
                       AND A.CD_STATUS = 'atendido'
                       AND A.DT_HORA_INICIO >= '2026-10-01'
                       AND A.DT_HORA_INICIO <  '2026-11-01'
WHERE S.IN_ATIVO = TRUE
GROUP BY S.NR_CONSULTORIO
ORDER BY S.NR_CONSULTORIO;

-- G10 — Qual é a taxa de falta por mês (consultas em que o paciente não veio)?
-- Atende: KPI de faltas da Seção 14. Período: agosto a novembro de 2026.
SELECT DATE_FORMAT(A.DT_HORA_INICIO, '%Y-%m')                          AS mes,
       SUM(A.CD_STATUS = 'atendido')                                   AS atendidas,
       SUM(A.CD_STATUS = 'falta')                                      AS faltas,
       SUM(A.CD_STATUS IN ('agendado', 'confirmado'))                  AS ainda_por_vir,
       ROUND(100 * SUM(A.CD_STATUS = 'falta')
                 / NULLIF(SUM(A.CD_STATUS IN ('atendido', 'falta')), 0), 1) AS falta_pct
FROM AGENDAMENTO A
WHERE A.DT_HORA_INICIO >= '2026-08-01' AND A.DT_HORA_INICIO < '2026-12-01'
GROUP BY DATE_FORMAT(A.DT_HORA_INICIO, '%Y-%m')
ORDER BY mes;

-- G11 — De onde vêm os pacientes (anúncio, indicação, fachada, parceria) e qual origem converte mais?
-- Atende: KPI de origem dos pacientes da Seção 14 (apoio ao marketing).
SELECT P.TP_ORIGEM                                                     AS origem,
       COUNT(DISTINCT P.ID_PACIENTE)                                   AS pacientes,
       COUNT(DISTINCT CT.ID_CONTRATO)                                  AS com_contrato,
       ROUND(100 * COUNT(DISTINCT CT.ID_CONTRATO) / COUNT(DISTINCT P.ID_PACIENTE), 1) AS conversao_pct,
       IFNULL(SUM(CT.VL_CONTRATADO), 0)                                AS valor_contratado
FROM PACIENTE P
LEFT JOIN ORCAMENTO O  ON O.ID_PACIENTE = P.ID_PACIENTE
LEFT JOIN CONTRATO CT  ON CT.ID_ORCAMENTO = O.ID_ORCAMENTO
GROUP BY P.TP_ORIGEM
ORDER BY valor_contratado DESC;

-- G12 — Quais orçamentos estão parados em negociação há mais de 30 dias (para o comercial ligar)?
-- Atende: P3 e o KPI de conversão da Seção 14.
SELECT O.ID_ORCAMENTO,
       P.NM_PACIENTE                           AS paciente,
       (SELECT GROUP_CONCAT(T.NR_TELEFONE SEPARATOR ' / ')
          FROM TELEFONE_PACIENTE T
         WHERE T.ID_PACIENTE = P.ID_PACIENTE)  AS telefones,
       O.DT_EMISSAO                            AS emitido_em,
       DATEDIFF(CURDATE(), O.DT_EMISSAO)       AS dias_parado,
       O.VL_TOTAL                              AS valor,
       IFNULL(C.NM_COLABORADOR, 'sem comercial atribuído') AS comercial
FROM ORCAMENTO O
JOIN PACIENTE P          ON P.ID_PACIENTE = O.ID_PACIENTE
LEFT JOIN COLABORADOR C  ON C.ID_COLABORADOR = O.ID_COLABORADOR_COMERCIAL
WHERE O.CD_STATUS = 'em_negociacao'
  AND DATEDIFF(CURDATE(), O.DT_EMISSAO) > 30
ORDER BY dias_parado DESC;

-- G13 — Qual é a taxa de inadimplência hoje (quanto do valor já vencido ainda não foi pago)?
-- Atende: P4 (inadimplência) e o KPI de inadimplência da Seção 14.
--         Conta como não paga qualquer parcela vencida sem baixa, inclusive a que
--         ficou marcada como "aberta" por engano (ver A03).
SELECT COUNT(*)                                                         AS parcelas_vencidas,
       SUM(VL_PARCELA)                                                  AS valor_vencido,
       SUM(CASE WHEN CD_STATUS = 'paga' THEN VL_PARCELA ELSE 0 END)     AS valor_pago,
       SUM(CASE WHEN CD_STATUS <> 'paga' THEN VL_PARCELA ELSE 0 END)    AS valor_sem_pagar,
       ROUND(100 * SUM(CASE WHEN CD_STATUS <> 'paga' THEN VL_PARCELA ELSE 0 END)
                 / SUM(VL_PARCELA), 1)                                  AS inadimplencia_pct
FROM PARCELA
WHERE DT_VENCIMENTO <= CURDATE();

-- G14 — Dos retornos pós-alta que já venceram, quantos foram feitos (taxa de retorno)?
-- Atende: P5 (retorno depois da alta) e o KPI de retorno da Seção 14.
SELECT COUNT(*)                                                         AS retornos_vencidos,
       SUM(CASE WHEN RET.ID_AGENDAMENTO IS NOT NULL THEN 1 ELSE 0 END)  AS retornos_feitos,
       ROUND(100 * SUM(CASE WHEN RET.ID_AGENDAMENTO IS NOT NULL THEN 1 ELSE 0 END)
                 / COUNT(*), 1)                                         AS retorno_pct
FROM AGENDAMENTO ALTA
LEFT JOIN AGENDAMENTO RET ON RET.ID_PACIENTE = ALTA.ID_PACIENTE
                         AND RET.TP_AGENDAMENTO = 'retorno'
                         AND RET.CD_STATUS = 'atendido'
                         AND RET.DT_HORA_INICIO > ALTA.DT_HORA_INICIO
WHERE ALTA.TP_AGENDAMENTO = 'alta'
  AND ALTA.CD_STATUS = 'atendido'
  AND ALTA.DT_RETORNO_PREVISTO <= CURDATE();
