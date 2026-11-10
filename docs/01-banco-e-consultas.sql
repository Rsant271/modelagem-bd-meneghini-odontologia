-- ============================================================================
-- Meneghini Odontologia Integrada: banco de dados do trabalho
-- Disciplina: Modelagem de Banco de Dados (UNICID, 2026.2)
-- Arquivo 1 de 2: criação do banco, manipulação e consultas
-- (o arquivo 2, 02-massa-de-dados.sql, só carrega os dados fictícios)
--
-- Este arquivo tem 4 partes:
--   Parte 1  criação do banco, das 16 tabelas, das chaves e dos gatilhos
--   Parte 2  manipulação dos dados (SELECT com JOIN, UPDATE, DELETE)
--   Parte 3  consultas gerenciais (G01 a G14)
--   Parte 4  consultas de auditoria (A01 a A10)
--
-- Ordem de execução: Parte 1 -> 02-massa-de-dados.sql -> Partes 2, 3 e 4.
-- A massa precisa das tabelas da Parte 1, e as consultas precisam da massa.
-- No MySQL Workbench: selecione o trecho e execute só a seleção. As linhas
-- "FIM DA PARTE n" marcam onde cada parte termina. No terminal: README, Seção 15.
--
-- SGBD: MySQL 8.0 ou mais novo (testado do zero em MySQL 26.10, macOS)
-- Dados: todos fictícios (LGPD). Nenhum dado real de paciente ou colaborador.
-- O modelo lógico, as 16 tabelas e as restrições estão no README (Seções 10 a 13)
-- e no dicionário de dados (dicionario/dicionario-de-dados.html).
-- ============================================================================

-- ============================================================================
-- PARTE 1: CRIAÇÃO DO BANCO, TABELAS, CHAVES E GATILHOS
-- Rodar primeiro. Apaga e recria o banco meneghini_odontologia do zero.
-- ============================================================================
-- ----------------------------------------------------------------------------
-- 1. Banco de dados
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS meneghini_odontologia;
CREATE DATABASE meneghini_odontologia
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE meneghini_odontologia;

-- ----------------------------------------------------------------------------
-- 2. Tabelas (na ordem em que uma depende da outra)
--    As chaves estrangeiras entram depois, com ALTER TABLE, no item 3 desta parte.
-- ----------------------------------------------------------------------------

-- Cadastro do paciente, aberto pela recepção quando ele comparece à avaliação (RN17)
CREATE TABLE PACIENTE (
    ID_PACIENTE     INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    NM_PACIENTE     VARCHAR(120)    NOT NULL,
    NR_CPF          CHAR(11)        NOT NULL,
    DT_NASCIMENTO   DATE            NOT NULL,
    DS_EMAIL        VARCHAR(120)    NULL,
    DS_LOGRADOURO   VARCHAR(150)    NOT NULL,
    NM_BAIRRO       VARCHAR(80)     NOT NULL,
    NR_CEP          CHAR(8)         NOT NULL,
    DT_CADASTRO     DATE            NOT NULL DEFAULT (CURRENT_DATE),
    TP_ORIGEM       ENUM('anuncio', 'indicacao', 'fachada', 'parceria') NOT NULL,
    CONSTRAINT PK_PACIENTE      PRIMARY KEY (ID_PACIENTE),
    CONSTRAINT UK_PACIENTE_CPF  UNIQUE (NR_CPF),
    CONSTRAINT CK_PACIENTE_CPF  CHECK (NR_CPF REGEXP '^[0-9]{11}$'),
    INDEX IX_PACIENTE_NOME (NM_PACIENTE)
);

-- Telefones do paciente: um por linha (saída do atributo multivalorado, 1FN)
CREATE TABLE TELEFONE_PACIENTE (
    ID_PACIENTE     INT UNSIGNED    NOT NULL,
    NR_TELEFONE     VARCHAR(15)     NOT NULL,
    CONSTRAINT PK_TELEFONE_PACIENTE PRIMARY KEY (ID_PACIENTE, NR_TELEFONE)
);

-- Colaboradores de qualquer cargo; o CRO só existe para dentista e diretor clínico
CREATE TABLE COLABORADOR (
    ID_COLABORADOR  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    NM_COLABORADOR  VARCHAR(120)    NOT NULL,
    NR_CPF          CHAR(11)        NOT NULL,
    TP_CARGO        VARCHAR(40)     NOT NULL,
    NM_SETOR        VARCHAR(40)     NOT NULL,
    NR_CRO          VARCHAR(20)     NULL,
    DT_ADMISSAO     DATE            NOT NULL,
    IN_ATIVO        BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_COLABORADOR       PRIMARY KEY (ID_COLABORADOR),
    CONSTRAINT UK_COLABORADOR_CPF   UNIQUE (NR_CPF),
    CONSTRAINT UK_COLABORADOR_CRO   UNIQUE (NR_CRO),
    CONSTRAINT CK_COLABORADOR_CPF   CHECK (NR_CPF REGEXP '^[0-9]{11}$'),
    CONSTRAINT CK_COLABORADOR_CRO   CHECK (TP_CARGO NOT IN ('dentista', 'diretor clinico') OR NR_CRO IS NOT NULL),
    INDEX IX_COLABORADOR_CARGO (TP_CARGO, IN_ATIVO)
);

-- Especialidades mantidas pela gestora (RN24)
CREATE TABLE ESPECIALIDADE (
    ID_ESPECIALIDADE    INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    NM_ESPECIALIDADE    VARCHAR(60)     NOT NULL,
    DS_ESPECIALIDADE    VARCHAR(255)    NULL,
    CONSTRAINT PK_ESPECIALIDADE     PRIMARY KEY (ID_ESPECIALIDADE),
    CONSTRAINT UK_ESPECIALIDADE_NM  UNIQUE (NM_ESPECIALIDADE)
);

-- Tabela intermediária do N:N POSSUI: um dentista pode ter mais de uma especialidade (RN14)
CREATE TABLE COLABORADOR_ESPECIALIDADE (
    ID_COLABORADOR      INT UNSIGNED    NOT NULL,
    ID_ESPECIALIDADE    INT UNSIGNED    NOT NULL,
    CONSTRAINT PK_COLABORADOR_ESPECIALIDADE PRIMARY KEY (ID_COLABORADOR, ID_ESPECIALIDADE)
);

-- Salas com cadeira odontológica
CREATE TABLE CONSULTORIO (
    ID_CONSULTORIO  INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    NR_CONSULTORIO  TINYINT UNSIGNED    NOT NULL,
    IN_ATIVO        BOOLEAN             NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_CONSULTORIO       PRIMARY KEY (ID_CONSULTORIO),
    CONSTRAINT UK_CONSULTORIO_NR    UNIQUE (NR_CONSULTORIO)
);

-- Tabela de preços, mantida pela gestora (RN24); a avaliação custa zero (RN01)
CREATE TABLE PROCEDIMENTO (
    ID_PROCEDIMENTO INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    CD_PROCEDIMENTO VARCHAR(10)         NOT NULL,
    NM_PROCEDIMENTO VARCHAR(100)        NOT NULL,
    DS_PROCEDIMENTO TEXT                NULL,
    VL_TABELA       DECIMAL(10,2)       NOT NULL,
    QT_DURACAO_MIN  SMALLINT UNSIGNED   NULL,
    CONSTRAINT PK_PROCEDIMENTO      PRIMARY KEY (ID_PROCEDIMENTO),
    CONSTRAINT UK_PROCEDIMENTO_CD   UNIQUE (CD_PROCEDIMENTO),
    CONSTRAINT CK_PROCEDIMENTO_VL   CHECK (VL_TABELA >= 0),
    INDEX IX_PROCEDIMENTO_NOME (NM_PROCEDIMENTO)
);

-- Orçamento montado pelo dentista avaliador (RN02) e negociado pelo comercial
CREATE TABLE ORCAMENTO (
    ID_ORCAMENTO                INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    ID_PACIENTE                 INT UNSIGNED    NOT NULL,
    ID_COLABORADOR_AVALIADOR    INT UNSIGNED    NOT NULL,
    ID_COLABORADOR_COMERCIAL    INT UNSIGNED    NULL,
    DT_EMISSAO                  DATE            NOT NULL,
    VL_TOTAL                    DECIMAL(10,2)   NOT NULL DEFAULT 0,
    CD_STATUS                   ENUM('em_negociacao', 'aprovado', 'aprovado_parcial', 'recusado') NOT NULL DEFAULT 'em_negociacao',
    CONSTRAINT PK_ORCAMENTO PRIMARY KEY (ID_ORCAMENTO),
    INDEX IX_ORCAMENTO_PACIENTE (ID_PACIENTE, DT_EMISSAO),
    INDEX IX_ORCAMENTO_STATUS (CD_STATUS)
);

-- Itens do orçamento (entidade fraca): aprovação e execução item a item (RN04, RN12)
CREATE TABLE ITEM_ORCAMENTO (
    ID_ORCAMENTO        INT UNSIGNED        NOT NULL,
    NR_ITEM             SMALLINT UNSIGNED   NOT NULL,
    ID_PROCEDIMENTO     INT UNSIGNED        NOT NULL,
    NR_DENTE            TINYINT UNSIGNED    NULL,
    TP_FASE             ENUM('cirurgica', 'protetica', 'ambas') NULL,
    VL_NEGOCIADO        DECIMAL(10,2)       NOT NULL,
    CD_STATUS_APROVACAO ENUM('pendente', 'aprovado', 'recusado') NOT NULL DEFAULT 'pendente',
    CD_STATUS_EXECUCAO  ENUM('em_aberto', 'concluido') NOT NULL DEFAULT 'em_aberto',
    CONSTRAINT PK_ITEM_ORCAMENTO    PRIMARY KEY (ID_ORCAMENTO, NR_ITEM),
    CONSTRAINT CK_ITEM_DENTE        CHECK (NR_DENTE BETWEEN 11 AND 48),
    CONSTRAINT CK_ITEM_VL           CHECK (VL_NEGOCIADO >= 0),
    INDEX IX_ITEM_EXECUCAO (CD_STATUS_EXECUCAO)
);

-- Contrato gerado pelos itens aprovados (RN05); forma de pagamento e entrada (RN06)
CREATE TABLE CONTRATO (
    ID_CONTRATO         INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    ID_ORCAMENTO        INT UNSIGNED        NOT NULL,
    DT_ASSINATURA       DATE                NOT NULL,
    VL_CONTRATADO       DECIMAL(10,2)       NOT NULL,
    TP_FORMA_PAGAMENTO  ENUM('a_vista', 'cartao_parcelado', 'boleto_parcelado') NOT NULL,
    QT_PARCELAS         TINYINT UNSIGNED    NOT NULL DEFAULT 1,
    VL_ENTRADA          DECIMAL(10,2)       NULL,
    CONSTRAINT PK_CONTRATO          PRIMARY KEY (ID_CONTRATO),
    CONSTRAINT UK_CONTRATO_ORCAMENTO UNIQUE (ID_ORCAMENTO),
    CONSTRAINT CK_CONTRATO_VL       CHECK (VL_CONTRATADO > 0),
    CONSTRAINT CK_CONTRATO_QT       CHECK (QT_PARCELAS >= 1),
    CONSTRAINT CK_CONTRATO_A_VISTA  CHECK (TP_FORMA_PAGAMENTO <> 'a_vista' OR QT_PARCELAS = 1),
    CONSTRAINT CK_CONTRATO_ENTRADA  CHECK (TP_FORMA_PAGAMENTO <> 'boleto_parcelado' OR VL_ENTRADA >= 0.20 * VL_CONTRATADO),
    INDEX IX_CONTRATO_DATA (DT_ASSINATURA)
);

-- Parcelas mensais do contrato (entidade fraca); baixa uma a uma (RN07, RN19)
CREATE TABLE PARCELA (
    ID_CONTRATO     INT UNSIGNED        NOT NULL,
    NR_PARCELA      TINYINT UNSIGNED    NOT NULL,
    VL_PARCELA      DECIMAL(10,2)       NOT NULL,
    DT_VENCIMENTO   DATE                NOT NULL,
    DT_PAGAMENTO    DATE                NULL,
    CD_STATUS       ENUM('aberta', 'paga', 'atrasada') NOT NULL DEFAULT 'aberta',
    CONSTRAINT PK_PARCELA       PRIMARY KEY (ID_CONTRATO, NR_PARCELA),
    CONSTRAINT CK_PARCELA_VL    CHECK (VL_PARCELA > 0),
    CONSTRAINT CK_PARCELA_PAGA  CHECK (CD_STATUS <> 'paga' OR DT_PAGAMENTO IS NOT NULL),
    INDEX IX_PARCELA_COBRANCA (CD_STATUS, DT_VENCIMENTO)
);

-- Agenda: um paciente, um dentista, um consultório, uma data e hora (RN09, RN10)
-- Sem UNIQUE em sala e horário: o horário de uma falta pode receber encaixe (RN11)
CREATE TABLE AGENDAMENTO (
    ID_AGENDAMENTO      INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    ID_PACIENTE         INT UNSIGNED        NOT NULL,
    ID_COLABORADOR      INT UNSIGNED        NOT NULL,
    ID_CONSULTORIO      INT UNSIGNED        NOT NULL,
    DT_HORA_INICIO      DATETIME            NOT NULL,
    QT_DURACAO_MIN      SMALLINT UNSIGNED   NOT NULL,
    TP_AGENDAMENTO      ENUM('avaliacao', 'tratamento', 'alta', 'retorno') NOT NULL,
    CD_STATUS           ENUM('agendado', 'confirmado', 'atendido', 'falta', 'reagendado') NOT NULL DEFAULT 'agendado',
    DS_OBSERVACAO       VARCHAR(255)        NULL,
    DT_RETORNO_PREVISTO DATE                NULL,
    CONSTRAINT PK_AGENDAMENTO       PRIMARY KEY (ID_AGENDAMENTO),
    CONSTRAINT CK_AGENDAMENTO_DUR   CHECK (QT_DURACAO_MIN > 0),
    CONSTRAINT CK_AGENDAMENTO_RET   CHECK (DT_RETORNO_PREVISTO IS NULL OR TP_AGENDAMENTO = 'alta'),
    INDEX IX_AGENDAMENTO_SALA (ID_CONSULTORIO, DT_HORA_INICIO),
    INDEX IX_AGENDAMENTO_DENTISTA (ID_COLABORADOR, DT_HORA_INICIO),
    INDEX IX_AGENDAMENTO_DATA (DT_HORA_INICIO),
    INDEX IX_AGENDAMENTO_PACIENTE (ID_PACIENTE),
    INDEX IX_AGENDAMENTO_RETORNO (DT_RETORNO_PREVISTO)
);

-- Tabela intermediária do N:N EXECUTA: quais itens do plano foram feitos em cada consulta (RN12)
CREATE TABLE AGENDAMENTO_ITEM (
    ID_AGENDAMENTO  INT UNSIGNED        NOT NULL,
    ID_ORCAMENTO    INT UNSIGNED        NOT NULL,
    NR_ITEM         SMALLINT UNSIGNED   NOT NULL,
    CONSTRAINT PK_AGENDAMENTO_ITEM PRIMARY KEY (ID_AGENDAMENTO, ID_ORCAMENTO, NR_ITEM)
);

-- Evolução clínica: dado sensível de saúde, uma por consulta atendida (RN16)
CREATE TABLE EVOLUCAO_CLINICA (
    ID_EVOLUCAO         INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    ID_AGENDAMENTO      INT UNSIGNED        NOT NULL,
    DT_REGISTRO         DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DS_EVOLUCAO         TEXT                NOT NULL,
    NR_DENTE            TINYINT UNSIGNED    NULL,
    DS_PROXIMOS_PASSOS  TEXT                NULL,
    CONSTRAINT PK_EVOLUCAO_CLINICA  PRIMARY KEY (ID_EVOLUCAO),
    CONSTRAINT UK_EVOLUCAO_AGEND    UNIQUE (ID_AGENDAMENTO)
);

-- Pedido ao laboratório da clínica, por paciente, solicitado por um dentista (RN15)
CREATE TABLE PEDIDO_LABORATORIO (
    ID_PEDIDO           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    ID_PACIENTE         INT UNSIGNED    NOT NULL,
    ID_COLABORADOR      INT UNSIGNED    NOT NULL,
    DT_SOLICITACAO      DATE            NOT NULL DEFAULT (CURRENT_DATE),
    DS_PECA             VARCHAR(255)    NOT NULL,
    DT_PRAZO_ENTREGA    DATE            NOT NULL,
    DT_ENTREGA          DATE            NULL,
    CD_STATUS           ENUM('solicitado', 'em_producao', 'pronto', 'entregue') NOT NULL DEFAULT 'solicitado',
    CONSTRAINT PK_PEDIDO_LABORATORIO    PRIMARY KEY (ID_PEDIDO),
    CONSTRAINT CK_PEDIDO_PRAZO          CHECK (DT_PRAZO_ENTREGA >= DT_SOLICITACAO),
    CONSTRAINT CK_PEDIDO_ENTREGA        CHECK (CD_STATUS <> 'entregue' OR DT_ENTREGA IS NOT NULL),
    INDEX IX_PEDIDO_FILA (CD_STATUS, DT_PRAZO_ENTREGA),
    INDEX IX_PEDIDO_PACIENTE (ID_PACIENTE)
);

-- Log de alterações, preenchido pelos gatilhos do item 4 desta parte (RNF05)
CREATE TABLE LOG_ALTERACAO (
    ID_LOG          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    DT_HORA         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NM_USUARIO_BD   VARCHAR(80)     NOT NULL,
    ID_COLABORADOR  INT UNSIGNED    NULL,
    NM_TABELA       VARCHAR(40)     NOT NULL,
    ID_REGISTRO     VARCHAR(40)     NOT NULL,
    TP_OPERACAO     ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    DS_ANTES        TEXT            NULL,
    DS_DEPOIS       TEXT            NULL,
    CONSTRAINT PK_LOG_ALTERACAO PRIMARY KEY (ID_LOG),
    INDEX IX_LOG_TABELA (NM_TABELA, ID_REGISTRO)
);

-- ----------------------------------------------------------------------------
-- 3. Chaves estrangeiras (19 ligações do modelo lógico)
--    Todas com ON DELETE RESTRICT: na clínica nenhum papel apaga registro.
--    Única exceção: o telefone acompanha o paciente (ON DELETE CASCADE).
-- ----------------------------------------------------------------------------
ALTER TABLE TELEFONE_PACIENTE
    ADD CONSTRAINT FK_TELEFONE_PACIENTE FOREIGN KEY (ID_PACIENTE)
        REFERENCES PACIENTE (ID_PACIENTE) ON DELETE CASCADE;

ALTER TABLE COLABORADOR_ESPECIALIDADE
    ADD CONSTRAINT FK_COLESP_COLABORADOR FOREIGN KEY (ID_COLABORADOR)
        REFERENCES COLABORADOR (ID_COLABORADOR) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_COLESP_ESPECIALIDADE FOREIGN KEY (ID_ESPECIALIDADE)
        REFERENCES ESPECIALIDADE (ID_ESPECIALIDADE) ON DELETE RESTRICT;

ALTER TABLE ORCAMENTO
    ADD CONSTRAINT FK_ORCAMENTO_PACIENTE FOREIGN KEY (ID_PACIENTE)
        REFERENCES PACIENTE (ID_PACIENTE) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_ORCAMENTO_AVALIADOR FOREIGN KEY (ID_COLABORADOR_AVALIADOR)
        REFERENCES COLABORADOR (ID_COLABORADOR) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_ORCAMENTO_COMERCIAL FOREIGN KEY (ID_COLABORADOR_COMERCIAL)
        REFERENCES COLABORADOR (ID_COLABORADOR) ON DELETE RESTRICT;

ALTER TABLE ITEM_ORCAMENTO
    ADD CONSTRAINT FK_ITEM_ORCAMENTO FOREIGN KEY (ID_ORCAMENTO)
        REFERENCES ORCAMENTO (ID_ORCAMENTO) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_ITEM_PROCEDIMENTO FOREIGN KEY (ID_PROCEDIMENTO)
        REFERENCES PROCEDIMENTO (ID_PROCEDIMENTO) ON DELETE RESTRICT;

ALTER TABLE CONTRATO
    ADD CONSTRAINT FK_CONTRATO_ORCAMENTO FOREIGN KEY (ID_ORCAMENTO)
        REFERENCES ORCAMENTO (ID_ORCAMENTO) ON DELETE RESTRICT;

ALTER TABLE PARCELA
    ADD CONSTRAINT FK_PARCELA_CONTRATO FOREIGN KEY (ID_CONTRATO)
        REFERENCES CONTRATO (ID_CONTRATO) ON DELETE RESTRICT;

ALTER TABLE AGENDAMENTO
    ADD CONSTRAINT FK_AGENDAMENTO_PACIENTE FOREIGN KEY (ID_PACIENTE)
        REFERENCES PACIENTE (ID_PACIENTE) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_AGENDAMENTO_DENTISTA FOREIGN KEY (ID_COLABORADOR)
        REFERENCES COLABORADOR (ID_COLABORADOR) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_AGENDAMENTO_CONSULTORIO FOREIGN KEY (ID_CONSULTORIO)
        REFERENCES CONSULTORIO (ID_CONSULTORIO) ON DELETE RESTRICT;

ALTER TABLE AGENDAMENTO_ITEM
    ADD CONSTRAINT FK_AGITEM_AGENDAMENTO FOREIGN KEY (ID_AGENDAMENTO)
        REFERENCES AGENDAMENTO (ID_AGENDAMENTO) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_AGITEM_ITEM FOREIGN KEY (ID_ORCAMENTO, NR_ITEM)
        REFERENCES ITEM_ORCAMENTO (ID_ORCAMENTO, NR_ITEM) ON DELETE RESTRICT;

ALTER TABLE EVOLUCAO_CLINICA
    ADD CONSTRAINT FK_EVOLUCAO_AGENDAMENTO FOREIGN KEY (ID_AGENDAMENTO)
        REFERENCES AGENDAMENTO (ID_AGENDAMENTO) ON DELETE RESTRICT;

ALTER TABLE PEDIDO_LABORATORIO
    ADD CONSTRAINT FK_PEDIDO_PACIENTE FOREIGN KEY (ID_PACIENTE)
        REFERENCES PACIENTE (ID_PACIENTE) ON DELETE RESTRICT,
    ADD CONSTRAINT FK_PEDIDO_DENTISTA FOREIGN KEY (ID_COLABORADOR)
        REFERENCES COLABORADOR (ID_COLABORADOR) ON DELETE RESTRICT;

ALTER TABLE LOG_ALTERACAO
    ADD CONSTRAINT FK_LOG_COLABORADOR FOREIGN KEY (ID_COLABORADOR)
        REFERENCES COLABORADOR (ID_COLABORADOR) ON DELETE RESTRICT;

-- ----------------------------------------------------------------------------
-- 4. Gatilhos (triggers) que alimentam LOG_ALTERACAO
--    Cobrem o que o RNF05 pede: baixa de parcela, mudança de situação do
--    agendamento e do item do orçamento e qualquer escrita na evolução clínica.
--    NM_USUARIO_BD vem do próprio MySQL. ID_COLABORADOR vem da variável
--    @ID_COLABORADOR_LOGADO, que a aplicação informa ao abrir a sessão
--    (fica vazio quando ninguém informou).
--    Obs.: os gatilhos precisam do comando DELIMITER (MySQL Workbench ou
--    cliente mysql); em ferramentas de navegador que não aceitam DELIMITER,
--    rode o arquivo até aqui e crie os gatilhos um a um.
-- ----------------------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER TRG_PARCELA_UPDATE
AFTER UPDATE ON PARCELA
FOR EACH ROW
BEGIN
    IF NOT (OLD.CD_STATUS <=> NEW.CD_STATUS) OR NOT (OLD.DT_PAGAMENTO <=> NEW.DT_PAGAMENTO) THEN
        INSERT INTO LOG_ALTERACAO (NM_USUARIO_BD, ID_COLABORADOR, NM_TABELA, ID_REGISTRO, TP_OPERACAO, DS_ANTES, DS_DEPOIS)
        VALUES (CURRENT_USER(), @ID_COLABORADOR_LOGADO, 'PARCELA',
                CONCAT(OLD.ID_CONTRATO, '-', OLD.NR_PARCELA), 'UPDATE',
                CONCAT('status=', OLD.CD_STATUS, '; pagamento=', IFNULL(OLD.DT_PAGAMENTO, 'vazio')),
                CONCAT('status=', NEW.CD_STATUS, '; pagamento=', IFNULL(NEW.DT_PAGAMENTO, 'vazio')));
    END IF;
END$$

CREATE TRIGGER TRG_AGENDAMENTO_UPDATE
AFTER UPDATE ON AGENDAMENTO
FOR EACH ROW
BEGIN
    IF NOT (OLD.CD_STATUS <=> NEW.CD_STATUS) THEN
        INSERT INTO LOG_ALTERACAO (NM_USUARIO_BD, ID_COLABORADOR, NM_TABELA, ID_REGISTRO, TP_OPERACAO, DS_ANTES, DS_DEPOIS)
        VALUES (CURRENT_USER(), @ID_COLABORADOR_LOGADO, 'AGENDAMENTO', OLD.ID_AGENDAMENTO, 'UPDATE',
                CONCAT('status=', OLD.CD_STATUS), CONCAT('status=', NEW.CD_STATUS));
    END IF;
END$$

CREATE TRIGGER TRG_ITEM_ORCAMENTO_UPDATE
AFTER UPDATE ON ITEM_ORCAMENTO
FOR EACH ROW
BEGIN
    IF NOT (OLD.CD_STATUS_APROVACAO <=> NEW.CD_STATUS_APROVACAO)
       OR NOT (OLD.CD_STATUS_EXECUCAO <=> NEW.CD_STATUS_EXECUCAO)
       OR NOT (OLD.VL_NEGOCIADO <=> NEW.VL_NEGOCIADO) THEN
        INSERT INTO LOG_ALTERACAO (NM_USUARIO_BD, ID_COLABORADOR, NM_TABELA, ID_REGISTRO, TP_OPERACAO, DS_ANTES, DS_DEPOIS)
        VALUES (CURRENT_USER(), @ID_COLABORADOR_LOGADO, 'ITEM_ORCAMENTO',
                CONCAT(OLD.ID_ORCAMENTO, '-', OLD.NR_ITEM), 'UPDATE',
                CONCAT('aprovacao=', OLD.CD_STATUS_APROVACAO, '; execucao=', OLD.CD_STATUS_EXECUCAO, '; valor=', OLD.VL_NEGOCIADO),
                CONCAT('aprovacao=', NEW.CD_STATUS_APROVACAO, '; execucao=', NEW.CD_STATUS_EXECUCAO, '; valor=', NEW.VL_NEGOCIADO));
    END IF;
END$$

CREATE TRIGGER TRG_EVOLUCAO_INSERT
AFTER INSERT ON EVOLUCAO_CLINICA
FOR EACH ROW
BEGIN
    INSERT INTO LOG_ALTERACAO (NM_USUARIO_BD, ID_COLABORADOR, NM_TABELA, ID_REGISTRO, TP_OPERACAO, DS_ANTES, DS_DEPOIS)
    VALUES (CURRENT_USER(), @ID_COLABORADOR_LOGADO, 'EVOLUCAO_CLINICA', NEW.ID_EVOLUCAO, 'INSERT',
            NULL, CONCAT('agendamento=', NEW.ID_AGENDAMENTO));
END$$

CREATE TRIGGER TRG_EVOLUCAO_UPDATE
AFTER UPDATE ON EVOLUCAO_CLINICA
FOR EACH ROW
BEGIN
    INSERT INTO LOG_ALTERACAO (NM_USUARIO_BD, ID_COLABORADOR, NM_TABELA, ID_REGISTRO, TP_OPERACAO, DS_ANTES, DS_DEPOIS)
    VALUES (CURRENT_USER(), @ID_COLABORADOR_LOGADO, 'EVOLUCAO_CLINICA', OLD.ID_EVOLUCAO, 'UPDATE',
            LEFT(OLD.DS_EVOLUCAO, 200), LEFT(NEW.DS_EVOLUCAO, 200));
END$$

CREATE TRIGGER TRG_EVOLUCAO_DELETE
AFTER DELETE ON EVOLUCAO_CLINICA
FOR EACH ROW
BEGIN
    INSERT INTO LOG_ALTERACAO (NM_USUARIO_BD, ID_COLABORADOR, NM_TABELA, ID_REGISTRO, TP_OPERACAO, DS_ANTES, DS_DEPOIS)
    VALUES (CURRENT_USER(), @ID_COLABORADOR_LOGADO, 'EVOLUCAO_CLINICA', OLD.ID_EVOLUCAO, 'DELETE',
            LEFT(OLD.DS_EVOLUCAO, 200), NULL);
END$$

DELIMITER ;

-- Conferência rápida: as 16 tabelas e os 6 gatilhos criados
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'meneghini_odontologia'
ORDER BY TABLE_NAME;

SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'meneghini_odontologia'
ORDER BY TRIGGER_NAME;

-- ============================================================================
-- FIM DA PARTE 1 (criação)
-- ============================================================================

-- ============================================================================
-- PARTE 2: MANIPULAÇÃO DOS DADOS (SELECT COM JOIN, UPDATE, DELETE)
-- Rodar depois de 02-massa-de-dados.sql.
-- ============================================================================
-- Esta parte mostra o banco funcionando no dia a dia da clínica:
--   1. consultas com JOIN (o que a recepção, o dentista e o financeiro veem)
--   2. UPDATE: baixa de parcela e confirmação de consulta (com o log gravando)
--   3. DELETE barrado pela chave estrangeira (o erro é de propósito)
--   4. DELETE na ordem certa, usando registros de teste criados aqui mesmo
--
-- Atenção: o comando do item 3 dá erro de propósito (MySQL 1451). No MySQL
-- Workbench, desmarque "Stop script execution on errors" ou rode a partir do
-- comando seguinte. No cliente de terminal, use a opção --force.
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

-- ============================================================================
-- FIM DA PARTE 2 (manipulação)
-- ============================================================================

-- ============================================================================
-- PARTE 3: CONSULTAS GERENCIAIS (G01 A G14)
-- Rodar depois de 02-massa-de-dados.sql.
-- ============================================================================
-- Cada consulta responde a um problema da clínica (P1 a P5, README Seção 1)
-- ou calcula um indicador da Seção 14 (BI e IA). O cabeçalho de cada uma
-- diz a pergunta e o que ela atende. Todas devolvem linhas com a massa do
-- arquivo 02-massa-de-dados.sql.
--
-- Problemas (README, Seção 1):
--   P1 informação do paciente espalhada (sem histórico único)
--   P2 pedido ao laboratório sem registro e sem prazo
--   P3 orçamento aprovado em parte, sem controle do que foi feito
--   P4 inadimplência sem bloqueio automático do agendamento
--   P5 retorno depois da alta sem controle
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

-- ============================================================================
-- FIM DA PARTE 3 (consultas gerenciais)
-- ============================================================================

-- ============================================================================
-- PARTE 4: CONSULTAS DE AUDITORIA (A01 A A10)
-- Rodar depois de 02-massa-de-dados.sql.
-- ============================================================================
-- As consultas de auditoria conferem se os dados respeitam as regras de
-- negócio que o banco não consegue garantir sozinho com CHECK e FK (regras
-- que dependem de outra tabela ou de uma soma). Cada cabeçalho diz a
-- pergunta e a regra verificada. A massa do arquivo 02-massa-de-dados.sql tem casos errados de
-- propósito para que cada consulta devolva pelo menos uma linha; a A02 lista
-- todos os contratos com a situação, porque nela a massa está toda correta.
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

-- ============================================================================
-- FIM DA PARTE 4 (consultas de auditoria)
-- ============================================================================
