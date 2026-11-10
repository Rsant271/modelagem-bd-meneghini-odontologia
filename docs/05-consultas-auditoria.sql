-- ============================================================================
-- Meneghini Odontologia Integrada: banco de dados do trabalho
-- Arquivo 5 de 5: consultas de auditoria (A01 a A10)
-- Rodar depois de 03-manipulacao.sql.
--
-- As consultas de auditoria conferem se os dados respeitam as regras de
-- negócio que o banco não consegue garantir sozinho com CHECK e FK (regras
-- que dependem de outra tabela ou de uma soma). Cada cabeçalho diz a
-- pergunta e a regra verificada. A massa do arquivo 2 tem casos errados de
-- propósito para que cada consulta devolva pelo menos uma linha; a A02 lista
-- todos os contratos com a situação, porque nela a massa está toda correta.
-- ============================================================================
USE meneghini_odontologia;

-- A01 — Existe orçamento cujo VL_TOTAL não bate com a soma dos itens?
-- Verifica: RN03 (preço do orçamento) e a decisão de guardar VL_TOTAL como total derivado (Seção 11, 3FN).
SELECT O.ID_ORCAMENTO,
       P.NM_PACIENTE              AS paciente,
       O.VL_TOTAL                 AS total_gravado,
       SUM(I.VL_NEGOCIADO)        AS soma_dos_itens,
       O.VL_TOTAL - SUM(I.VL_NEGOCIADO) AS diferenca
FROM ORCAMENTO O
JOIN PACIENTE P       ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN ITEM_ORCAMENTO I ON I.ID_ORCAMENTO = O.ID_ORCAMENTO
GROUP BY O.ID_ORCAMENTO, P.NM_PACIENTE, O.VL_TOTAL
HAVING O.VL_TOTAL <> SUM(I.VL_NEGOCIADO);

-- A02 — O valor de cada contrato bate com os itens aprovados, e a entrada mais as parcelas fecham o contrato?
-- Verifica: RN05 (contrato nasce dos itens aprovados) e RN07 (parcelas do contrato).
SELECT CT.ID_CONTRATO,
       P.NM_PACIENTE                                        AS paciente,
       CT.VL_CONTRATADO                                     AS contratado,
       ITENS.soma_aprovados                                 AS itens_aprovados,
       IFNULL(CT.VL_ENTRADA, 0) + PARC.soma_parcelas        AS entrada_mais_parcelas,
       IF(CT.VL_CONTRATADO = ITENS.soma_aprovados, 'ok', 'DIVERGE')                               AS confere_itens,
       IF(CT.VL_CONTRATADO = IFNULL(CT.VL_ENTRADA, 0) + PARC.soma_parcelas, 'ok', 'DIVERGE')      AS confere_parcelas
FROM CONTRATO CT
JOIN ORCAMENTO O ON O.ID_ORCAMENTO = CT.ID_ORCAMENTO
JOIN PACIENTE P  ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN (SELECT ID_ORCAMENTO, SUM(VL_NEGOCIADO) AS soma_aprovados
      FROM ITEM_ORCAMENTO
      WHERE CD_STATUS_APROVACAO = 'aprovado'
      GROUP BY ID_ORCAMENTO) ITENS ON ITENS.ID_ORCAMENTO = CT.ID_ORCAMENTO
JOIN (SELECT ID_CONTRATO, SUM(VL_PARCELA) AS soma_parcelas
      FROM PARCELA
      GROUP BY ID_CONTRATO) PARC ON PARC.ID_CONTRATO = CT.ID_CONTRATO
ORDER BY CT.ID_CONTRATO;

-- A03 — Há parcela com vencimento passado que continua marcada como "aberta" em vez de "atrasada"?
-- Verifica: RN18 (cobrança de quem atrasa) e RN19 (bloqueio com duas parcelas sem pagar).
SELECT PA.ID_CONTRATO,
       PA.NR_PARCELA,
       P.NM_PACIENTE                         AS paciente,
       PA.VL_PARCELA                         AS valor,
       PA.DT_VENCIMENTO                      AS vencimento,
       DATEDIFF(CURDATE(), PA.DT_VENCIMENTO) AS dias_vencida,
       PA.CD_STATUS                          AS situacao_gravada,
       'deveria estar "atrasada"'            AS correcao
FROM PARCELA PA
JOIN CONTRATO CT ON CT.ID_CONTRATO = PA.ID_CONTRATO
JOIN ORCAMENTO O ON O.ID_ORCAMENTO = CT.ID_ORCAMENTO
JOIN PACIENTE P  ON P.ID_PACIENTE = O.ID_PACIENTE
WHERE PA.CD_STATUS = 'aberta'
  AND PA.DT_VENCIMENTO < CURDATE()
ORDER BY PA.DT_VENCIMENTO;

-- A04 — Alguma consulta atendida ficou sem evolução clínica?
-- Verifica: RN16 (toda consulta atendida gera evolução no prontuário).
SELECT A.ID_AGENDAMENTO,
       A.DT_HORA_INICIO        AS data_hora,
       P.NM_PACIENTE           AS paciente,
       C.NM_COLABORADOR        AS dentista,
       A.TP_AGENDAMENTO        AS tipo,
       A.CD_STATUS             AS situacao
FROM AGENDAMENTO A
JOIN PACIENTE P              ON P.ID_PACIENTE = A.ID_PACIENTE
JOIN COLABORADOR C           ON C.ID_COLABORADOR = A.ID_COLABORADOR
LEFT JOIN EVOLUCAO_CLINICA E ON E.ID_AGENDAMENTO = A.ID_AGENDAMENTO
WHERE A.CD_STATUS = 'atendido'
  AND E.ID_EVOLUCAO IS NULL
ORDER BY A.DT_HORA_INICIO;

-- A05 — Existem dois agendamentos ativos no mesmo consultório, ou com o mesmo dentista, em horários que se sobrepõem?
-- Verifica: RN09 e RN10 (um consultório e um dentista por horário) e RF07 (aviso de conflito de agenda).
-- O banco não tem UNIQUE aqui de propósito: o encaixe no horário de uma falta é permitido (RN11).
SELECT A1.ID_AGENDAMENTO                                  AS agendamento_1,
       A2.ID_AGENDAMENTO                                  AS agendamento_2,
       A1.DT_HORA_INICIO                                  AS inicio_1,
       A1.DT_HORA_INICIO + INTERVAL A1.QT_DURACAO_MIN MINUTE AS fim_1,
       A2.DT_HORA_INICIO                                  AS inicio_2,
       P1.NM_PACIENTE                                     AS paciente_1,
       P2.NM_PACIENTE                                     AS paciente_2,
       IF(A1.ID_CONSULTORIO = A2.ID_CONSULTORIO, CONCAT('consultório ', S.NR_CONSULTORIO), '-') AS mesmo_consultorio,
       IF(A1.ID_COLABORADOR = A2.ID_COLABORADOR, C.NM_COLABORADOR, '-')                        AS mesmo_dentista
FROM AGENDAMENTO A1
JOIN AGENDAMENTO A2 ON A2.ID_AGENDAMENTO > A1.ID_AGENDAMENTO
                   AND (A1.ID_CONSULTORIO = A2.ID_CONSULTORIO OR A1.ID_COLABORADOR = A2.ID_COLABORADOR)
                   AND A2.DT_HORA_INICIO <  A1.DT_HORA_INICIO + INTERVAL A1.QT_DURACAO_MIN MINUTE
                   AND A1.DT_HORA_INICIO <  A2.DT_HORA_INICIO + INTERVAL A2.QT_DURACAO_MIN MINUTE
JOIN PACIENTE P1    ON P1.ID_PACIENTE = A1.ID_PACIENTE
JOIN PACIENTE P2    ON P2.ID_PACIENTE = A2.ID_PACIENTE
JOIN CONSULTORIO S  ON S.ID_CONSULTORIO = A1.ID_CONSULTORIO
JOIN COLABORADOR C  ON C.ID_COLABORADOR = A1.ID_COLABORADOR
WHERE A1.CD_STATUS IN ('agendado', 'confirmado', 'atendido')
  AND A2.CD_STATUS IN ('agendado', 'confirmado', 'atendido')
ORDER BY A1.DT_HORA_INICIO;

-- A06 — Algum paciente bloqueado (duas ou mais parcelas atrasadas) tem consulta marcada?
-- Verifica: RN19 (bloqueio do agendamento) e RF17 (sistema impede agendar paciente bloqueado).
SELECT P.ID_PACIENTE,
       P.NM_PACIENTE                 AS paciente,
       BLOQ.parcelas_atrasadas,
       A.ID_AGENDAMENTO              AS agendamento,
       A.DT_HORA_INICIO              AS data_hora,
       A.CD_STATUS                   AS situacao,
       C.NM_COLABORADOR              AS dentista
FROM (SELECT O.ID_PACIENTE, COUNT(*) AS parcelas_atrasadas
      FROM PARCELA PA
      JOIN CONTRATO CT ON CT.ID_CONTRATO = PA.ID_CONTRATO
      JOIN ORCAMENTO O ON O.ID_ORCAMENTO = CT.ID_ORCAMENTO
      WHERE PA.CD_STATUS = 'atrasada'
      GROUP BY O.ID_PACIENTE
      HAVING COUNT(*) >= 2) BLOQ
JOIN PACIENTE P    ON P.ID_PACIENTE = BLOQ.ID_PACIENTE
JOIN AGENDAMENTO A ON A.ID_PACIENTE = P.ID_PACIENTE
               AND A.CD_STATUS IN ('agendado', 'confirmado')
               AND A.DT_HORA_INICIO >= CURDATE()
JOIN COLABORADOR C ON C.ID_COLABORADOR = A.ID_COLABORADOR
ORDER BY A.DT_HORA_INICIO;

-- A07 — Há pedido de laboratório com prazo vencido e ainda não entregue?
-- Verifica: RN15 (pedido ao laboratório com prazo) e o problema P2.
SELECT L.ID_PEDIDO,
       P.NM_PACIENTE                           AS paciente,
       L.DS_PECA                               AS peca,
       L.DT_PRAZO_ENTREGA                      AS prazo,
       DATEDIFF(CURDATE(), L.DT_PRAZO_ENTREGA) AS dias_de_atraso,
       L.CD_STATUS                             AS situacao,
       A.DT_HORA_INICIO                        AS consulta_que_depende_da_peca
FROM PEDIDO_LABORATORIO L
JOIN PACIENTE P         ON P.ID_PACIENTE = L.ID_PACIENTE
LEFT JOIN AGENDAMENTO A ON A.ID_PACIENTE = L.ID_PACIENTE
                       AND A.CD_STATUS IN ('agendado', 'confirmado')
                       AND A.DT_HORA_INICIO >= L.DT_SOLICITACAO
WHERE L.CD_STATUS <> 'entregue'
  AND L.DT_PRAZO_ENTREGA < CURDATE()
ORDER BY L.DT_PRAZO_ENTREGA;

-- A08 — Existe item marcado como concluído sem uma consulta atendida que o tenha executado?
-- Verifica: RN12 (item passa a concluído quando é executado em uma consulta).
SELECT I.ID_ORCAMENTO,
       I.NR_ITEM,
       P.NM_PACIENTE          AS paciente,
       PR.NM_PROCEDIMENTO     AS procedimento,
       I.CD_STATUS_EXECUCAO   AS situacao_gravada,
       'concluído sem consulta ligada' AS problema
FROM ITEM_ORCAMENTO I
JOIN ORCAMENTO O     ON O.ID_ORCAMENTO = I.ID_ORCAMENTO
JOIN PACIENTE P      ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN PROCEDIMENTO PR ON PR.ID_PROCEDIMENTO = I.ID_PROCEDIMENTO
WHERE I.CD_STATUS_EXECUCAO = 'concluido'
  AND NOT EXISTS (SELECT 1
                  FROM AGENDAMENTO_ITEM AI
                  JOIN AGENDAMENTO A ON A.ID_AGENDAMENTO = AI.ID_AGENDAMENTO
                  WHERE AI.ID_ORCAMENTO = I.ID_ORCAMENTO
                    AND AI.NR_ITEM = I.NR_ITEM
                    AND A.CD_STATUS = 'atendido')
ORDER BY I.ID_ORCAMENTO, I.NR_ITEM;

-- A09 — Alguma consulta de alta foi feita por dentista que não é o diretor clínico?
-- Verifica: RN20 (a alta é com o diretor clínico).
SELECT A.ID_AGENDAMENTO,
       A.DT_HORA_INICIO      AS data_hora,
       P.NM_PACIENTE         AS paciente,
       C.NM_COLABORADOR      AS quem_fez,
       C.TP_CARGO            AS cargo,
       'alta deveria ser com o diretor clínico' AS problema
FROM AGENDAMENTO A
JOIN PACIENTE P    ON P.ID_PACIENTE = A.ID_PACIENTE
JOIN COLABORADOR C ON C.ID_COLABORADOR = A.ID_COLABORADOR
WHERE A.TP_AGENDAMENTO = 'alta'
  AND C.TP_CARGO <> 'diretor clinico'
ORDER BY A.DT_HORA_INICIO;

-- A10 — Quem alterou o quê nos últimos 30 dias (log de alterações)?
-- Verifica: RNF05 (rastreabilidade das alterações) e a LGPD (acesso ao dado de saúde deixa rastro).
SELECT L.NM_TABELA                                   AS tabela,
       L.TP_OPERACAO                                 AS operacao,
       L.NM_USUARIO_BD                               AS usuario_mysql,
       IFNULL(C.NM_COLABORADOR, '(carga inicial)')   AS colaborador,
       COUNT(*)                                      AS alteracoes,
       MIN(L.DT_HORA)                                AS primeira,
       MAX(L.DT_HORA)                                AS ultima
FROM LOG_ALTERACAO L
LEFT JOIN COLABORADOR C ON C.ID_COLABORADOR = L.ID_COLABORADOR
WHERE L.DT_HORA >= NOW() - INTERVAL 30 DAY
GROUP BY L.NM_TABELA, L.TP_OPERACAO, L.NM_USUARIO_BD, C.NM_COLABORADOR
ORDER BY L.NM_TABELA, L.TP_OPERACAO;
