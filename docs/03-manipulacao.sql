-- ============================================================================
-- Meneghini Odontologia Integrada: banco de dados do trabalho
-- Arquivo 3 de 5: manipulação dos dados (SELECT com JOIN, UPDATE, DELETE)
-- Rodar depois de 02-massa-de-dados.sql.
--
-- Este arquivo mostra o banco funcionando no dia a dia da clínica:
--   1. consultas com JOIN (o que a recepção, o dentista e o financeiro veem)
--   2. UPDATE: baixa de parcela e confirmação de consulta (com o log gravando)
--   3. DELETE barrado pela chave estrangeira (o erro é de propósito)
--   4. DELETE na ordem certa, usando registros de teste criados aqui mesmo
--
-- Atenção: o comando da parte 3 dá erro de propósito (MySQL 1451). No MySQL
-- Workbench, desmarque "Stop script execution on errors" ou rode a partir do
-- comando seguinte. No cliente de terminal, use a opção --force.
-- ============================================================================
USE meneghini_odontologia;

-- ----------------------------------------------------------------------------
-- 1. SELECT com JOIN
-- ----------------------------------------------------------------------------

-- 1.1 Agenda de um dia (18/11/2026): paciente, dentista, consultório e procedimento previsto
SELECT A.ID_AGENDAMENTO,
       TIME(A.DT_HORA_INICIO)                                  AS horario,
       A.QT_DURACAO_MIN                                        AS minutos,
       P.NM_PACIENTE                                           AS paciente,
       C.NM_COLABORADOR                                        AS dentista,
       S.NR_CONSULTORIO                                        AS consultorio,
       A.TP_AGENDAMENTO                                        AS tipo,
       A.CD_STATUS                                             AS situacao,
       GROUP_CONCAT(PR.NM_PROCEDIMENTO ORDER BY I.NR_ITEM SEPARATOR '; ') AS procedimentos
FROM AGENDAMENTO A
JOIN PACIENTE P          ON P.ID_PACIENTE = A.ID_PACIENTE
JOIN COLABORADOR C       ON C.ID_COLABORADOR = A.ID_COLABORADOR
JOIN CONSULTORIO S       ON S.ID_CONSULTORIO = A.ID_CONSULTORIO
LEFT JOIN AGENDAMENTO_ITEM AI ON AI.ID_AGENDAMENTO = A.ID_AGENDAMENTO
LEFT JOIN ITEM_ORCAMENTO I    ON I.ID_ORCAMENTO = AI.ID_ORCAMENTO AND I.NR_ITEM = AI.NR_ITEM
LEFT JOIN PROCEDIMENTO PR     ON PR.ID_PROCEDIMENTO = I.ID_PROCEDIMENTO
WHERE DATE(A.DT_HORA_INICIO) = '2026-11-18'
GROUP BY A.ID_AGENDAMENTO, A.DT_HORA_INICIO, A.QT_DURACAO_MIN, P.NM_PACIENTE,
         C.NM_COLABORADOR, S.NR_CONSULTORIO, A.TP_AGENDAMENTO, A.CD_STATUS
ORDER BY A.DT_HORA_INICIO, S.NR_CONSULTORIO;

-- 1.2 Orçamento de um paciente, item a item (orçamento 2: aprovação parcial)
SELECT O.ID_ORCAMENTO,
       P.NM_PACIENTE                   AS paciente,
       I.NR_ITEM                       AS item,
       PR.CD_PROCEDIMENTO              AS codigo,
       PR.NM_PROCEDIMENTO              AS procedimento,
       I.NR_DENTE                      AS dente,
       PR.VL_TABELA                    AS valor_tabela,
       I.VL_NEGOCIADO                  AS valor_negociado,
       I.CD_STATUS_APROVACAO           AS aprovacao,
       I.CD_STATUS_EXECUCAO            AS execucao,
       O.CD_STATUS                     AS situacao_orcamento
FROM ORCAMENTO O
JOIN PACIENTE P        ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN ITEM_ORCAMENTO I  ON I.ID_ORCAMENTO = O.ID_ORCAMENTO
JOIN PROCEDIMENTO PR   ON PR.ID_PROCEDIMENTO = I.ID_PROCEDIMENTO
WHERE O.ID_ORCAMENTO = 2
ORDER BY I.NR_ITEM;

-- 1.3 Dentistas e suas especialidades (um dentista pode ter mais de uma, RN14)
SELECT C.NM_COLABORADOR                                            AS dentista,
       C.NR_CRO                                                   AS cro,
       GROUP_CONCAT(E.NM_ESPECIALIDADE ORDER BY E.NM_ESPECIALIDADE SEPARATOR ', ') AS especialidades,
       IF(C.IN_ATIVO, 'ativo', 'desligado')                       AS situacao
FROM COLABORADOR C
JOIN COLABORADOR_ESPECIALIDADE CE ON CE.ID_COLABORADOR = C.ID_COLABORADOR
JOIN ESPECIALIDADE E              ON E.ID_ESPECIALIDADE = CE.ID_ESPECIALIDADE
GROUP BY C.ID_COLABORADOR, C.NM_COLABORADOR, C.NR_CRO, C.IN_ATIVO
ORDER BY C.NM_COLABORADOR;

-- 1.4 Carnê de um contrato: parcelas com situação (contrato 6, paciente bloqueado)
SELECT CT.ID_CONTRATO,
       P.NM_PACIENTE          AS paciente,
       CT.TP_FORMA_PAGAMENTO  AS forma,
       CT.VL_CONTRATADO       AS contratado,
       CT.VL_ENTRADA          AS entrada,
       PA.NR_PARCELA          AS parcela,
       PA.VL_PARCELA          AS valor,
       PA.DT_VENCIMENTO       AS vencimento,
       PA.DT_PAGAMENTO        AS pagamento,
       PA.CD_STATUS           AS situacao
FROM CONTRATO CT
JOIN ORCAMENTO O  ON O.ID_ORCAMENTO = CT.ID_ORCAMENTO
JOIN PACIENTE P   ON P.ID_PACIENTE = O.ID_PACIENTE
JOIN PARCELA PA   ON PA.ID_CONTRATO = CT.ID_CONTRATO
WHERE CT.ID_CONTRATO = 6
ORDER BY PA.NR_PARCELA;

-- 1.5 LEFT JOIN: todo paciente avaliado e se fechou contrato ou não
SELECT P.ID_PACIENTE,
       P.NM_PACIENTE                                   AS paciente,
       P.TP_ORIGEM                                     AS origem,
       O.CD_STATUS                                     AS situacao_orcamento,
       IFNULL(CT.VL_CONTRATADO, 0)                     AS valor_contratado,
       IF(CT.ID_CONTRATO IS NULL, 'sem contrato', 'com contrato') AS resultado
FROM PACIENTE P
JOIN ORCAMENTO O       ON O.ID_PACIENTE = P.ID_PACIENTE
LEFT JOIN CONTRATO CT  ON CT.ID_ORCAMENTO = O.ID_ORCAMENTO
ORDER BY resultado DESC, P.NM_PACIENTE;

-- ----------------------------------------------------------------------------
-- 2. UPDATE (os gatilhos gravam cada mudança em LOG_ALTERACAO)
-- ----------------------------------------------------------------------------

-- 2.1 O financeiro (colaborador 11) dá baixa na parcela 2 do contrato 10, paga hoje
SET @ID_COLABORADOR_LOGADO = 11;

UPDATE PARCELA
SET DT_PAGAMENTO = '2026-11-10',
    CD_STATUS    = 'paga'
WHERE ID_CONTRATO = 10
  AND NR_PARCELA  = 2;

-- 2.2 A recepção (colaborador 9) confirma a consulta 69 por telefone
SET @ID_COLABORADOR_LOGADO = 9;

UPDATE AGENDAMENTO
SET CD_STATUS = 'confirmado'
WHERE ID_AGENDAMENTO = 69;

-- 2.3 O laboratório avisa que a coroa do pedido 6 ficou pronta (sem gatilho nesta tabela)
UPDATE PEDIDO_LABORATORIO
SET CD_STATUS = 'pronto'
WHERE ID_PEDIDO = 6;

-- 2.4 O que o log gravou: quem mudou o quê, com o valor antes e depois
SELECT L.ID_LOG,
       L.DT_HORA,
       L.NM_USUARIO_BD      AS usuario_mysql,
       C.NM_COLABORADOR     AS colaborador,
       L.NM_TABELA          AS tabela,
       L.ID_REGISTRO        AS registro,
       L.TP_OPERACAO        AS operacao,
       L.DS_ANTES           AS antes,
       L.DS_DEPOIS          AS depois
FROM LOG_ALTERACAO L
LEFT JOIN COLABORADOR C ON C.ID_COLABORADOR = L.ID_COLABORADOR
WHERE L.TP_OPERACAO = 'UPDATE'
ORDER BY L.ID_LOG;

SET @ID_COLABORADOR_LOGADO = NULL;

-- ----------------------------------------------------------------------------
-- 3. DELETE barrado pela chave estrangeira (erro de propósito)
--    O paciente 4 recusou o orçamento, mas tem orçamento e agendamento
--    gravados. Como todas as FKs são ON DELETE RESTRICT, o MySQL recusa:
--    "Cannot delete or update a parent row: a foreign key constraint fails"
--    (erro 1451). É assim que o banco protege o histórico (RNF05, LGPD).
-- ----------------------------------------------------------------------------
DELETE FROM PACIENTE WHERE ID_PACIENTE = 4;

-- O paciente continua lá:
SELECT ID_PACIENTE, NM_PACIENTE, DT_CADASTRO FROM PACIENTE WHERE ID_PACIENTE = 4;

-- ----------------------------------------------------------------------------
-- 4. DELETE na ordem certa
--    Para não apagar a massa, criamos um paciente de teste com telefone,
--    orçamento e item, e apagamos de baixo para cima: item -> orçamento ->
--    paciente. O telefone vai junto com o paciente (ON DELETE CASCADE).
-- ----------------------------------------------------------------------------
INSERT INTO PACIENTE (ID_PACIENTE, NM_PACIENTE, NR_CPF, DT_NASCIMENTO, DS_LOGRADOURO, NM_BAIRRO, NR_CEP, DT_CADASTRO, TP_ORIGEM)
VALUES (99, 'Paciente de Teste', '99999999999', '1990-01-01', 'Rua de Teste, 1', 'Santana', '02000000', '2026-11-10', 'fachada');

INSERT INTO TELEFONE_PACIENTE (ID_PACIENTE, NR_TELEFONE) VALUES (99, '11999990099');

INSERT INTO ORCAMENTO (ID_ORCAMENTO, ID_PACIENTE, ID_COLABORADOR_AVALIADOR, DT_EMISSAO, VL_TOTAL, CD_STATUS)
VALUES (99, 99, 3, '2026-11-10', 180.00, 'em_negociacao');

INSERT INTO ITEM_ORCAMENTO (ID_ORCAMENTO, NR_ITEM, ID_PROCEDIMENTO, VL_NEGOCIADO)
VALUES (99, 1, 2, 180.00);

-- Antes: 1 paciente, 1 telefone, 1 orçamento, 1 item
SELECT (SELECT COUNT(*) FROM PACIENTE WHERE ID_PACIENTE = 99)          AS pacientes,
       (SELECT COUNT(*) FROM TELEFONE_PACIENTE WHERE ID_PACIENTE = 99) AS telefones,
       (SELECT COUNT(*) FROM ORCAMENTO WHERE ID_ORCAMENTO = 99)        AS orcamentos,
       (SELECT COUNT(*) FROM ITEM_ORCAMENTO WHERE ID_ORCAMENTO = 99)   AS itens;

-- Ordem certa: primeiro quem depende, depois quem é referenciado
DELETE FROM ITEM_ORCAMENTO WHERE ID_ORCAMENTO = 99;
DELETE FROM ORCAMENTO      WHERE ID_ORCAMENTO = 99;
DELETE FROM PACIENTE       WHERE ID_PACIENTE  = 99;   -- o telefone sai junto (CASCADE)

-- Depois: tudo zero, sem precisar apagar o telefone à mão
SELECT (SELECT COUNT(*) FROM PACIENTE WHERE ID_PACIENTE = 99)          AS pacientes,
       (SELECT COUNT(*) FROM TELEFONE_PACIENTE WHERE ID_PACIENTE = 99) AS telefones,
       (SELECT COUNT(*) FROM ORCAMENTO WHERE ID_ORCAMENTO = 99)        AS orcamentos,
       (SELECT COUNT(*) FROM ITEM_ORCAMENTO WHERE ID_ORCAMENTO = 99)   AS itens;
