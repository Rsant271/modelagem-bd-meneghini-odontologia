-- ============================================================================
-- Meneghini Odontologia Integrada: banco de dados do trabalho
-- Arquivo 2 de 5: massa de dados fictícia (INSERT)
-- Rodar depois de 01-criacao.sql.
--
-- Todos os dados são inventados (LGPD): nomes, CPFs, endereços, telefones,
-- e-mails e valores. Nenhum paciente ou colaborador aqui existe de verdade.
--
-- Volume e período: a clínica tem 7 consultórios, 4 especialidades, cerca de
-- 30 colaboradores e 1 laboratório próprio (README, Seção 1). A massa é um
-- recorte de agosto a novembro de 2026 com 26 pacientes, 17 colaboradores
-- (6 dentistas), 26 orçamentos, 20 contratos, 76 parcelas e 75 agendamentos.
-- Não é o movimento inteiro da clínica: é o suficiente para cada consulta
-- dos arquivos 4 e 5 devolver linhas e para todos os casos aparecerem.
--
-- Casos propositais (para as consultas gerenciais e de auditoria):
--   . orçamento recusado (pacientes 4 e 12) e em negociação (7, 14, 18, 24)
--   . orçamento aprovado em parte (pacientes 2, 9 e 16)
--   . paciente com 2 parcelas atrasadas, bloqueado (paciente 8), e com 1 (paciente 6)
--   . parcela vencida que continua marcada como "aberta" (contrato 1, parcela 3)
--   . paciente bloqueado com consulta marcada (agendamento 31)
--   . consulta atendida sem evolução clínica registrada (agendamento 54)
--   . item concluído sem o agendamento que o executou (orçamento 17, item 2)
--   . dois agendamentos sobrepostos no mesmo consultório e dentista (47 e 74)
--   . pedido de laboratório com prazo vencido e não entregue (pedido 2)
--   . alta com retorno previsto já vencido e sem retorno marcado (paciente 26)
--   . consulta de alta feita por dentista comum, não pelo diretor clínico (agendamento 35)
--   . orçamento com VL_TOTAL diferente da soma dos itens (orçamento 14)
--   . faltas (agendamentos 39, 63 e 66), reagendamento (46) e encaixe (40)
--   . formas de pagamento: à vista, cartão parcelado e boleto com entrada de 20%
-- ============================================================================
USE meneghini_odontologia;

-- A carga inicial é feita pelo administrador do banco; nenhum colaborador
-- logado, então o log registra só o usuário do MySQL.
SET @ID_COLABORADOR_LOGADO = NULL;

-- ----------------------------------------------------------------------------
-- 1. Cadastros de apoio (mantidos pela gestora, RN24)
-- ----------------------------------------------------------------------------
INSERT INTO ESPECIALIDADE (ID_ESPECIALIDADE, NM_ESPECIALIDADE, DS_ESPECIALIDADE) VALUES
(1, 'Implantodontia', 'Implantes, enxertos e coroas sobre implante'),
(2, 'Clínica geral',  'Limpeza, restauração, extração simples e clareamento'),
(3, 'Ortodontia',     'Aparelhos fixos e manutenções mensais'),
(4, 'Endodontia',     'Tratamento de canal');

INSERT INTO CONSULTORIO (ID_CONSULTORIO, NR_CONSULTORIO, IN_ATIVO) VALUES
(1, 1, TRUE), (2, 2, TRUE), (3, 3, TRUE), (4, 4, TRUE),
(5, 5, TRUE), (6, 6, TRUE), (7, 7, TRUE);

-- Tabela de preços. A avaliação custa zero (RN01).
INSERT INTO PROCEDIMENTO (ID_PROCEDIMENTO, CD_PROCEDIMENTO, NM_PROCEDIMENTO, DS_PROCEDIMENTO, VL_TABELA, QT_DURACAO_MIN) VALUES
(1,  'AV01', 'Avaliação inicial',                     'Exame clínico, anamnese e plano de tratamento',        0.00,    30),
(2,  'CG01', 'Limpeza (profilaxia)',                  'Remoção de placa e tártaro',                            180.00,  40),
(3,  'CG02', 'Restauração em resina',                 'Por dente',                                              250.00,  50),
(4,  'CG03', 'Extração simples',                      'Por dente',                                              300.00,  40),
(5,  'CG04', 'Clareamento dental',                    'Clareamento em consultório, arcadas superior e inferior', 900.00, 60),
(6,  'EN01', 'Tratamento de canal (unirradicular)',   'Dente com uma raiz',                                     800.00,  90),
(7,  'EN02', 'Tratamento de canal (multirradicular)', 'Dente com duas ou mais raízes',                          1200.00, 120),
(8,  'IM01', 'Implante unitário (fase cirúrgica)',    'Instalação do implante',                                 3500.00, 120),
(9,  'IM02', 'Coroa sobre implante (fase protética)', 'Moldagem e instalação da coroa',                         2500.00, 60),
(10, 'IM03', 'Enxerto ósseo',                         'Preparo para implante',                                  2200.00, 90),
(11, 'OR01', 'Instalação de aparelho ortodôntico',    'Aparelho fixo metálico',                                 1500.00, 60),
(12, 'OR02', 'Manutenção ortodôntica mensal',         'Troca de ligaduras e ajuste',                            150.00,  30),
(13, 'PR01', 'Coroa de porcelana',                    'Por dente, feita no laboratório da clínica',             1800.00, 60),
(14, 'PR02', 'Prótese total',                         'Por arcada, feita no laboratório da clínica',            2800.00, 90),
(15, 'PR03', 'Placa de bruxismo',                     'Feita no laboratório da clínica',                        450.00,  30);

-- ----------------------------------------------------------------------------
-- 2. Colaboradores (RN23). Só dentista e diretor clínico têm CRO.
--    O colaborador 17 está desligado (IN_ATIVO = FALSE).
-- ----------------------------------------------------------------------------
INSERT INTO COLABORADOR (ID_COLABORADOR, NM_COLABORADOR, NR_CPF, TP_CARGO, NM_SETOR, NR_CRO, DT_ADMISSAO, IN_ATIVO) VALUES
(1,  'Marcos Teixeira Alves',     '10000000001', 'diretor clinico', 'clinico',        'CRO-SP 45120', '2015-03-02', TRUE),
(2,  'Ana Beatriz Rocha',         '10000000002', 'dentista',        'clinico',        'CRO-SP 61234', '2019-08-12', TRUE),
(3,  'Carlos Henrique Lima',      '10000000003', 'dentista',        'clinico',        'CRO-SP 70311', '2020-02-03', TRUE),
(4,  'Juliana Prado Martins',     '10000000004', 'dentista',        'clinico',        'CRO-SP 58890', '2018-05-21', TRUE),
(5,  'Rafael Nogueira Dias',      '10000000005', 'dentista',        'clinico',        'CRO-SP 82045', '2022-01-10', TRUE),
(6,  'Patrícia Mendes Souza',     '10000000006', 'dentista',        'clinico',        'CRO-SP 66502', '2021-06-14', TRUE),
(7,  'Luciana Ferreira Campos',   '10000000007', 'asb',             'clinico',        NULL,           '2019-10-01', TRUE),
(8,  'Thiago Barbosa Ramos',      '10000000008', 'asb',             'clinico',        NULL,           '2023-03-20', TRUE),
(9,  'Fernanda Oliveira Costa',   '10000000009', 'recepcao',        'recepcao',       NULL,           '2020-07-06', TRUE),
(10, 'Bruna Santos Almeida',      '10000000010', 'recepcao',        'recepcao',       NULL,           '2024-02-19', TRUE),
(11, 'Roberto Carvalho Pinto',    '10000000011', 'financeiro',      'financeiro',     NULL,           '2017-11-13', TRUE),
(12, 'Priscila Ribeiro Gomes',    '10000000012', 'comercial',       'comercial',      NULL,           '2021-09-27', TRUE),
(13, 'Diego Araújo Silva',        '10000000013', 'relacionamento',  'comercial',      NULL,           '2023-08-14', TRUE),
(14, 'Vanessa Lopes Moreira',     '10000000014', 'laboratorio',     'laboratorio',    NULL,           '2016-04-04', TRUE),
(15, 'Gustavo Pereira Nunes',     '10000000015', 'marketing',       'marketing',      NULL,           '2024-06-03', TRUE),
(16, 'Simone Castro Duarte',      '10000000016', 'gestora',         'administrativo', NULL,           '2014-01-20', TRUE),
(17, 'Eduardo Martins Freitas',   '10000000017', 'dentista',        'clinico',        'CRO-SP 51777', '2017-02-06', FALSE);

-- Um dentista pode ter mais de uma especialidade (RN14)
INSERT INTO COLABORADOR_ESPECIALIDADE (ID_COLABORADOR, ID_ESPECIALIDADE) VALUES
(1, 1), (1, 2),
(2, 1),
(3, 2), (3, 4),
(4, 3),
(5, 4),
(6, 1), (6, 2),
(17, 3);

-- ----------------------------------------------------------------------------
-- 3. Pacientes (RN17: o cadastro nasce na avaliação) e telefones
--    Os pacientes 25 e 26 são de antes do recorte, para mostrar alta e retorno.
-- ----------------------------------------------------------------------------
INSERT INTO PACIENTE (ID_PACIENTE, NM_PACIENTE, NR_CPF, DT_NASCIMENTO, DS_EMAIL, DS_LOGRADOURO, NM_BAIRRO, NR_CEP, DT_CADASTRO, TP_ORIGEM) VALUES
(1,  'Mariana Souza Lima',          '20000000001', '1988-04-12', 'mariana.lima@exemplo.com',     'Rua das Acácias, 120',                     'Santana',                '02012000', '2026-08-03', 'anuncio'),
(2,  'João Pedro Alves',            '20000000002', '1975-11-30', NULL,                           'Avenida Guapira, 850',                     'Tucuruvi',               '02265000', '2026-08-04', 'indicacao'),
(3,  'Larissa Fernandes Costa',     '20000000003', '1995-02-18', 'larissa.costa@exemplo.com',    'Rua Jaçanã, 44',                           'Jaçanã',                 '02273000', '2026-08-05', 'anuncio'),
(4,  'Antônio Carlos Ribeiro',      '20000000004', '1962-07-07', NULL,                           'Rua Voluntários da Pátria, 2100',          'Santana',                '02011000', '2026-08-10', 'fachada'),
(5,  'Beatriz Oliveira Santos',     '20000000005', '2001-09-25', 'bia.santos@exemplo.com',       'Rua Maria Cândida, 310',                   'Vila Guilherme',         '02071000', '2026-08-11', 'anuncio'),
(6,  'Ricardo Mendes Araújo',       '20000000006', '1983-01-15', 'ricardo.araujo@exemplo.com',   'Avenida Nova Cantareira, 1500',            'Tremembé',               '02330000', '2026-08-12', 'parceria'),
(7,  'Carolina Rodrigues Pereira',  '20000000007', '1990-06-02', NULL,                           'Rua Alfredo Pujol, 600',                   'Santana',                '02017000', '2026-08-17', 'anuncio'),
(8,  'Fernando Gomes Barbosa',      '20000000008', '1970-03-22', 'fernando.gb@exemplo.com',      'Rua Doutor Zuquim, 980',                   'Santana',                '02035000', '2026-08-18', 'indicacao'),
(9,  'Patrícia Nunes Carvalho',     '20000000009', '1986-12-09', NULL,                           'Rua Conselheiro Moreira de Barros, 1200',  'Mandaqui',               '02430000', '2026-08-24', 'anuncio'),
(10, 'Lucas Martins Rocha',         '20000000010', '1998-08-14', 'lucas.rocha@exemplo.com',      'Rua Paulo Lincoln do Valle Pontin, 75',    'Jaçanã',                 '02276000', '2026-08-25', 'anuncio'),
(11, 'Sandra Regina Dias',          '20000000011', '1958-05-05', NULL,                           'Rua Professor Ernesto Marques, 330',       'Tucuruvi',               '02261000', '2026-09-01', 'fachada'),
(12, 'Gabriel Henrique Moura',      '20000000012', '1993-10-19', 'gabriel.moura@exemplo.com',    'Avenida Mazzei, 2200',                     'Tucuruvi',               '02310000', '2026-09-02', 'anuncio'),
(13, 'Juliana Castro Freitas',      '20000000013', '1981-02-27', 'ju.freitas@exemplo.com',       'Rua Leite de Morais, 140',                 'Santana',                '02021000', '2026-09-08', 'indicacao'),
(14, 'Marcelo Augusto Pinto',       '20000000014', '1966-09-11', NULL,                           'Rua Carolina Fonseca, 50',                 'Vila Maria',             '02114000', '2026-09-09', 'anuncio'),
(15, 'Aline Batista Correia',       '20000000015', '1992-04-03', 'aline.correia@exemplo.com',    'Rua Cruzeiro, 780',                        'Casa Verde',             '02511000', '2026-09-15', 'parceria'),
(16, 'Rodrigo Silva Teixeira',      '20000000016', '1979-07-28', NULL,                           'Rua Luiz Dumont Villares, 1100',           'Mandaqui',               '02420000', '2026-09-16', 'anuncio'),
(17, 'Vanessa Lima Monteiro',       '20000000017', '1987-11-08', 'vanessa.monteiro@exemplo.com', 'Rua Ezequiel Freire, 230',                 'Santana',                '02034000', '2026-09-22', 'anuncio'),
(18, 'Paulo Sérgio Andrade',        '20000000018', '1955-01-30', NULL,                           'Avenida Tucuruvi, 1300',                   'Tucuruvi',               '02304000', '2026-09-23', 'indicacao'),
(19, 'Isabela Ramos Cardoso',       '20000000019', '2003-03-17', 'isabela.rc@exemplo.com',       'Rua Tomé de Souza, 90',                    'Vila Guilherme',         '02050000', '2026-09-29', 'anuncio'),
(20, 'Daniel Correia Lopes',        '20000000020', '1984-06-21', NULL,                           'Rua Benjamim Pereira, 410',                'Jaçanã',                 '02279000', '2026-10-06', 'fachada'),
(21, 'Renata Albuquerque Vieira',   '20000000021', '1976-08-13', 'renata.vieira@exemplo.com',    'Rua Duarte de Azevedo, 500',               'Santana',                '02036000', '2026-10-07', 'anuncio'),
(22, 'Felipe Nascimento Cruz',      '20000000022', '1996-12-01', NULL,                           'Avenida Parada Pinto, 1700',               'Vila Nova Cachoeirinha', '02611000', '2026-10-13', 'anuncio'),
(23, 'Cláudia Moraes Pacheco',      '20000000023', '1969-10-24', 'claudia.pacheco@exemplo.com',  'Rua Doutor César, 220',                    'Santana',                '02013000', '2026-10-20', 'indicacao'),
(24, 'Henrique Dutra Figueiredo',   '20000000024', '1989-05-19', NULL,                           'Rua Capitão Rubens Marques, 65',           'Tremembé',               '02336000', '2026-11-03', 'anuncio'),
(25, 'Antônia Lima Prado',          '20000000025', '1972-03-14', NULL,                           'Rua Pedro Doll, 340',                      'Santana',                '02404000', '2026-02-10', 'indicacao'),
(26, 'Osvaldo Pinto Neves',         '20000000026', '1960-08-02', 'osvaldo.neves@exemplo.com',    'Rua Padre Chico, 155',                     'Mandaqui',               '02420010', '2026-03-02', 'fachada');

-- Telefones: alguns pacientes têm dois (celular e fixo)
INSERT INTO TELEFONE_PACIENTE (ID_PACIENTE, NR_TELEFONE) VALUES
(1, '11987000001'), (1, '1122000001'),
(2, '11987000002'),
(3, '11987000003'),
(4, '11987000004'), (4, '1122000004'),
(5, '11987000005'),
(6, '11987000006'),
(7, '11987000007'),
(8, '11987000008'), (8, '1122000008'),
(9, '11987000009'),
(10, '11987000010'),
(11, '11987000011'), (11, '1122000011'),
(12, '11987000012'),
(13, '11987000013'),
(14, '11987000014'),
(15, '11987000015'),
(16, '11987000016'),
(17, '11987000017'),
(18, '11987000018'), (18, '1122000018'),
(19, '11987000019'),
(20, '11987000020'),
(21, '11987000021'),
(22, '11987000022'),
(23, '11987000023'),
(24, '11987000024'),
(25, '11987000025'),
(26, '11987000026');

-- ----------------------------------------------------------------------------
-- 4. Orçamentos e itens (RN02, RN03, RN04). VL_TOTAL = soma de todos os itens.
--    Orçamento 14: VL_TOTAL gravado errado de propósito (11500; os itens somam 12000).
-- ----------------------------------------------------------------------------
INSERT INTO ORCAMENTO (ID_ORCAMENTO, ID_PACIENTE, ID_COLABORADOR_AVALIADOR, ID_COLABORADOR_COMERCIAL, DT_EMISSAO, VL_TOTAL, CD_STATUS) VALUES
(1,  1,  6, 12,   '2026-08-03', 5880.00,  'aprovado'),
(2,  2,  3, 12,   '2026-08-04', 3700.00,  'aprovado_parcial'),
(3,  3,  1, 13,   '2026-08-05', 1700.00,  'aprovado'),
(4,  4,  6, 12,   '2026-08-10', 3100.00,  'recusado'),
(5,  5,  3, 13,   '2026-08-11', 630.00,   'aprovado'),
(6,  6,  1, 12,   '2026-08-12', 7700.00,  'aprovado'),
(7,  7,  6, NULL, '2026-08-17', 1080.00,  'em_negociacao'),
(8,  8,  1, 12,   '2026-08-18', 5700.00,  'aprovado'),
(9,  9,  3, 13,   '2026-08-24', 2630.00,  'aprovado_parcial'),
(10, 10, 6, 12,   '2026-08-25', 1800.00,  'aprovado'),
(11, 11, 1, 12,   '2026-09-01', 3160.00,  'aprovado'),
(12, 12, 3, 13,   '2026-09-02', 1200.00,  'recusado'),
(13, 13, 6, 12,   '2026-09-08', 5900.00,  'aprovado'),
(14, 14, 1, 13,   '2026-09-09', 11500.00, 'em_negociacao'),
(15, 15, 3, 13,   '2026-09-15', 700.00,   'aprovado'),
(16, 16, 6, 12,   '2026-09-16', 1480.00,  'aprovado_parcial'),
(17, 17, 1, 12,   '2026-09-22', 1050.00,  'aprovado'),
(18, 18, 3, 13,   '2026-09-23', 3100.00,  'em_negociacao'),
(19, 19, 6, 12,   '2026-09-29', 1650.00,  'aprovado'),
(20, 20, 1, 13,   '2026-10-06', 430.00,   'aprovado'),
(21, 21, 3, 12,   '2026-10-07', 2900.00,  'aprovado'),
(22, 22, 6, 13,   '2026-10-13', 1080.00,  'aprovado'),
(23, 23, 1, 12,   '2026-10-20', 8200.00,  'aprovado'),
(24, 24, 3, NULL, '2026-11-03', 800.00,   'em_negociacao'),
(25, 25, 3, 13,   '2026-02-10', 180.00,   'aprovado'),
(26, 26, 6, 12,   '2026-03-02', 430.00,   'aprovado');

INSERT INTO ITEM_ORCAMENTO (ID_ORCAMENTO, NR_ITEM, ID_PROCEDIMENTO, NR_DENTE, TP_FASE, VL_NEGOCIADO, CD_STATUS_APROVACAO, CD_STATUS_EXECUCAO) VALUES
-- 1 Mariana: implante no 36 (cirúrgica feita, protética pendente) e limpeza
(1, 1, 8,  36,   'cirurgica', 3300.00, 'aprovado', 'concluido'),
(1, 2, 9,  36,   'protetica', 2400.00, 'aprovado', 'em_aberto'),
(1, 3, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
-- 2 João Pedro: canal e coroa aprovados, clareamento recusado (aprovação parcial)
(2, 1, 7,  46,   NULL,        1100.00, 'aprovado', 'concluido'),
(2, 2, 13, 46,   'protetica', 1700.00, 'aprovado', 'em_aberto'),
(2, 3, 5,  NULL, NULL,        900.00,  'recusado', 'em_aberto'),
-- 3 Larissa: aparelho e duas manutenções
(3, 1, 11, NULL, NULL,        1400.00, 'aprovado', 'concluido'),
(3, 2, 12, NULL, NULL,        150.00,  'aprovado', 'concluido'),
(3, 3, 12, NULL, NULL,        150.00,  'aprovado', 'concluido'),
-- 4 Antônio: recusou tudo
(4, 1, 14, NULL, 'protetica', 2800.00, 'recusado', 'em_aberto'),
(4, 2, 4,  31,   NULL,        300.00,  'recusado', 'em_aberto'),
-- 5 Beatriz: duas restaurações e limpeza, tudo feito (tem alta)
(5, 1, 3,  25,   NULL,        230.00,  'aprovado', 'concluido'),
(5, 2, 3,  14,   NULL,        230.00,  'aprovado', 'concluido'),
(5, 3, 2,  NULL, NULL,        170.00,  'aprovado', 'concluido'),
-- 6 Ricardo: enxerto feito, implante e coroa no 11 pendentes
(6, 1, 10, 11,   'cirurgica', 2000.00, 'aprovado', 'concluido'),
(6, 2, 8,  11,   'cirurgica', 3300.00, 'aprovado', 'em_aberto'),
(6, 3, 9,  11,   'protetica', 2400.00, 'aprovado', 'em_aberto'),
-- 7 Carolina: em negociação desde agosto
(7, 1, 5,  NULL, NULL,        900.00,  'pendente', 'em_aberto'),
(7, 2, 2,  NULL, NULL,        180.00,  'pendente', 'em_aberto'),
-- 8 Fernando: implante no 46 feito, coroa pendente (paciente bloqueado)
(8, 1, 8,  46,   'cirurgica', 3300.00, 'aprovado', 'concluido'),
(8, 2, 9,  46,   'protetica', 2400.00, 'aprovado', 'em_aberto'),
-- 9 Patrícia N.: canal e limpeza aprovados, coroa recusada (aprovação parcial)
(9, 1, 6,  21,   NULL,        750.00,  'aprovado', 'concluido'),
(9, 2, 13, 21,   'protetica', 1700.00, 'recusado', 'em_aberto'),
(9, 3, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
-- 10 Lucas: aparelho e manutenções (a terceira teve falta)
(10, 1, 11, NULL, NULL,       1500.00, 'aprovado', 'concluido'),
(10, 2, 12, NULL, NULL,       150.00,  'aprovado', 'concluido'),
(10, 3, 12, NULL, NULL,       150.00,  'aprovado', 'em_aberto'),
-- 11 Sandra: extrações feitas, prótese total pendente (no laboratório)
(11, 1, 14, NULL, 'protetica', 2600.00, 'aprovado', 'em_aberto'),
(11, 2, 4,  41,   NULL,        280.00,  'aprovado', 'concluido'),
(11, 3, 4,  31,   NULL,        280.00,  'aprovado', 'concluido'),
-- 12 Gabriel: recusou
(12, 1, 7,  36,   NULL,        1200.00, 'recusado', 'em_aberto'),
-- 13 Juliana C.: implante no 24, cirurgia marcada
(13, 1, 8,  24,   'cirurgica', 3400.00, 'aprovado', 'em_aberto'),
(13, 2, 9,  24,   'protetica', 2500.00, 'aprovado', 'em_aberto'),
-- 14 Marcelo: dois implantes em negociação (total gravado errado de propósito)
(14, 1, 8,  36,   'cirurgica', 3500.00, 'pendente', 'em_aberto'),
(14, 2, 8,  46,   'cirurgica', 3500.00, 'pendente', 'em_aberto'),
(14, 3, 9,  36,   'protetica', 2500.00, 'pendente', 'em_aberto'),
(14, 4, 9,  46,   'protetica', 2500.00, 'pendente', 'em_aberto'),
-- 15 Aline: restauração feita, placa de bruxismo pendente
(15, 1, 3,  36,   NULL,        250.00,  'aprovado', 'concluido'),
(15, 2, 15, NULL, NULL,        450.00,  'aprovado', 'em_aberto'),
-- 16 Rodrigo: limpeza e clareamento feitos, placa recusada (aprovação parcial)
(16, 1, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
(16, 2, 5,  NULL, NULL,        850.00,  'aprovado', 'concluido'),
(16, 3, 15, NULL, NULL,        450.00,  'recusado', 'em_aberto'),
-- 17 Vanessa L.: canal e restauração no 12, tudo feito (tem alta)
(17, 1, 6,  12,   NULL,        800.00,  'aprovado', 'concluido'),
(17, 2, 3,  12,   NULL,        250.00,  'aprovado', 'concluido'),
-- 18 Paulo Sérgio: em negociação
(18, 1, 14, NULL, 'protetica', 2800.00, 'pendente', 'em_aberto'),
(18, 2, 4,  11,   NULL,        300.00,  'pendente', 'em_aberto'),
-- 19 Isabela: aparelho e primeira manutenção
(19, 1, 11, NULL, NULL,        1500.00, 'aprovado', 'concluido'),
(19, 2, 12, NULL, NULL,        150.00,  'aprovado', 'concluido'),
-- 20 Daniel: limpeza feita, restauração pendente (faltou)
(20, 1, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
(20, 2, 3,  46,   NULL,        250.00,  'aprovado', 'em_aberto'),
-- 21 Renata: canal feito, coroa no laboratório
(21, 1, 7,  16,   NULL,        1150.00, 'aprovado', 'concluido'),
(21, 2, 13, 16,   'protetica', 1750.00, 'aprovado', 'em_aberto'),
-- 22 Felipe: limpeza e clareamento feitos
(22, 1, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
(22, 2, 5,  NULL, NULL,        900.00,  'aprovado', 'concluido'),
-- 23 Cláudia: enxerto, implante e coroa no 26, tudo pendente
(23, 1, 8,  26,   'cirurgica', 3500.00, 'aprovado', 'em_aberto'),
(23, 2, 9,  26,   'protetica', 2500.00, 'aprovado', 'em_aberto'),
(23, 3, 10, 26,   'cirurgica', 2200.00, 'aprovado', 'em_aberto'),
-- 24 Henrique: avaliado esta semana, ainda em negociação
(24, 1, 6,  22,   NULL,        800.00,  'pendente', 'em_aberto'),
-- 25 Antônia e 26 Osvaldo: tratamentos antigos, concluídos, com alta
(25, 1, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
(26, 1, 2,  NULL, NULL,        180.00,  'aprovado', 'concluido'),
(26, 2, 3,  36,   NULL,        250.00,  'aprovado', 'concluido');

-- ----------------------------------------------------------------------------
-- 5. Contratos (RN05, RN06) e parcelas (RN07)
--    VL_CONTRATADO = soma dos itens aprovados. No boleto, entrada de ao menos 20%.
-- ----------------------------------------------------------------------------
INSERT INTO CONTRATO (ID_CONTRATO, ID_ORCAMENTO, DT_ASSINATURA, VL_CONTRATADO, TP_FORMA_PAGAMENTO, QT_PARCELAS, VL_ENTRADA) VALUES
(1,  1,  '2026-08-05', 5880.00, 'boleto_parcelado', 6,  1200.00),
(2,  2,  '2026-08-06', 2800.00, 'cartao_parcelado', 4,  NULL),
(3,  3,  '2026-08-07', 1700.00, 'a_vista',          1,  NULL),
(4,  5,  '2026-08-11', 630.00,  'a_vista',          1,  NULL),
(5,  6,  '2026-08-14', 7700.00, 'boleto_parcelado', 6,  1700.00),
(6,  8,  '2026-08-20', 5700.00, 'boleto_parcelado', 8,  1300.00),
(7,  9,  '2026-08-26', 930.00,  'cartao_parcelado', 3,  NULL),
(8,  10, '2026-08-27', 1800.00, 'cartao_parcelado', 6,  NULL),
(9,  11, '2026-09-03', 3160.00, 'boleto_parcelado', 5,  700.00),
(10, 13, '2026-09-10', 5900.00, 'cartao_parcelado', 5,  NULL),
(11, 15, '2026-09-15', 700.00,  'a_vista',          1,  NULL),
(12, 16, '2026-09-18', 1030.00, 'cartao_parcelado', 2,  NULL),
(13, 17, '2026-09-24', 1050.00, 'boleto_parcelado', 3,  300.00),
(14, 19, '2026-10-01', 1650.00, 'cartao_parcelado', 5,  NULL),
(15, 20, '2026-10-06', 430.00,  'a_vista',          1,  NULL),
(16, 21, '2026-10-09', 2900.00, 'boleto_parcelado', 4,  700.00),
(17, 22, '2026-10-14', 1080.00, 'cartao_parcelado', 3,  NULL),
(18, 23, '2026-10-22', 8200.00, 'boleto_parcelado', 10, 1700.00),
(19, 25, '2026-02-10', 180.00,  'a_vista',          1,  NULL),
(20, 26, '2026-03-02', 430.00,  'a_vista',          1,  NULL);

-- Parcelas: no boleto, o valor parcelado é (contratado - entrada) / parcelas.
-- Contrato 1, parcela 3: venceu em 05/11 e continua "aberta" de propósito.
-- Contrato 6 (paciente 8): duas parcelas atrasadas, paciente bloqueado (RN19).
-- Contrato 10, parcela 2: vence em 10/11 e recebe baixa no arquivo 03.
INSERT INTO PARCELA (ID_CONTRATO, NR_PARCELA, VL_PARCELA, DT_VENCIMENTO, DT_PAGAMENTO, CD_STATUS) VALUES
(1, 1, 780.00, '2026-09-05', '2026-09-04', 'paga'),
(1, 2, 780.00, '2026-10-05', '2026-10-06', 'paga'),
(1, 3, 780.00, '2026-11-05', NULL,         'aberta'),
(1, 4, 780.00, '2026-12-05', NULL,         'aberta'),
(1, 5, 780.00, '2027-01-05', NULL,         'aberta'),
(1, 6, 780.00, '2027-02-05', NULL,         'aberta'),
(2, 1, 700.00, '2026-09-06', '2026-09-06', 'paga'),
(2, 2, 700.00, '2026-10-06', '2026-10-08', 'paga'),
(2, 3, 700.00, '2026-11-06', '2026-11-06', 'paga'),
(2, 4, 700.00, '2026-12-06', NULL,         'aberta'),
(3, 1, 1700.00, '2026-08-07', '2026-08-07', 'paga'),
(4, 1, 630.00,  '2026-08-11', '2026-08-11', 'paga'),
(5, 1, 1000.00, '2026-09-14', '2026-09-14', 'paga'),
(5, 2, 1000.00, '2026-10-14', NULL,         'atrasada'),
(5, 3, 1000.00, '2026-11-14', NULL,         'aberta'),
(5, 4, 1000.00, '2026-12-14', NULL,         'aberta'),
(5, 5, 1000.00, '2027-01-14', NULL,         'aberta'),
(5, 6, 1000.00, '2027-02-14', NULL,         'aberta'),
(6, 1, 550.00, '2026-09-20', NULL, 'atrasada'),
(6, 2, 550.00, '2026-10-20', NULL, 'atrasada'),
(6, 3, 550.00, '2026-11-20', NULL, 'aberta'),
(6, 4, 550.00, '2026-12-20', NULL, 'aberta'),
(6, 5, 550.00, '2027-01-20', NULL, 'aberta'),
(6, 6, 550.00, '2027-02-20', NULL, 'aberta'),
(6, 7, 550.00, '2027-03-20', NULL, 'aberta'),
(6, 8, 550.00, '2027-04-20', NULL, 'aberta'),
(7, 1, 310.00, '2026-09-26', '2026-09-26', 'paga'),
(7, 2, 310.00, '2026-10-26', '2026-10-26', 'paga'),
(7, 3, 310.00, '2026-11-26', NULL,         'aberta'),
(8, 1, 300.00, '2026-09-27', '2026-09-27', 'paga'),
(8, 2, 300.00, '2026-10-27', '2026-10-27', 'paga'),
(8, 3, 300.00, '2026-11-27', NULL,         'aberta'),
(8, 4, 300.00, '2026-12-27', NULL,         'aberta'),
(8, 5, 300.00, '2027-01-27', NULL,         'aberta'),
(8, 6, 300.00, '2027-02-27', NULL,         'aberta'),
(9, 1, 492.00, '2026-10-03', '2026-10-02', 'paga'),
(9, 2, 492.00, '2026-11-03', '2026-11-03', 'paga'),
(9, 3, 492.00, '2026-12-03', NULL,         'aberta'),
(9, 4, 492.00, '2027-01-03', NULL,         'aberta'),
(9, 5, 492.00, '2027-02-03', NULL,         'aberta'),
(10, 1, 1180.00, '2026-10-10', '2026-10-10', 'paga'),
(10, 2, 1180.00, '2026-11-10', NULL,         'aberta'),
(10, 3, 1180.00, '2026-12-10', NULL,         'aberta'),
(10, 4, 1180.00, '2027-01-10', NULL,         'aberta'),
(10, 5, 1180.00, '2027-02-10', NULL,         'aberta'),
(11, 1, 700.00, '2026-09-15', '2026-09-15', 'paga'),
(12, 1, 515.00, '2026-10-18', '2026-10-18', 'paga'),
(12, 2, 515.00, '2026-11-18', NULL,         'aberta'),
(13, 1, 250.00, '2026-10-24', '2026-10-23', 'paga'),
(13, 2, 250.00, '2026-11-24', NULL,         'aberta'),
(13, 3, 250.00, '2026-12-24', NULL,         'aberta'),
(14, 1, 330.00, '2026-11-01', '2026-11-01', 'paga'),
(14, 2, 330.00, '2026-12-01', NULL,         'aberta'),
(14, 3, 330.00, '2027-01-01', NULL,         'aberta'),
(14, 4, 330.00, '2027-02-01', NULL,         'aberta'),
(14, 5, 330.00, '2027-03-01', NULL,         'aberta'),
(15, 1, 430.00, '2026-10-06', '2026-10-06', 'paga'),
(16, 1, 550.00, '2026-11-09', '2026-11-09', 'paga'),
(16, 2, 550.00, '2026-12-09', NULL,         'aberta'),
(16, 3, 550.00, '2027-01-09', NULL,         'aberta'),
(16, 4, 550.00, '2027-02-09', NULL,         'aberta'),
(17, 1, 360.00, '2026-11-14', NULL, 'aberta'),
(17, 2, 360.00, '2026-12-14', NULL, 'aberta'),
(17, 3, 360.00, '2027-01-14', NULL, 'aberta'),
(18, 1,  650.00, '2026-11-22', NULL, 'aberta'),
(18, 2,  650.00, '2026-12-22', NULL, 'aberta'),
(18, 3,  650.00, '2027-01-22', NULL, 'aberta'),
(18, 4,  650.00, '2027-02-22', NULL, 'aberta'),
(18, 5,  650.00, '2027-03-22', NULL, 'aberta'),
(18, 6,  650.00, '2027-04-22', NULL, 'aberta'),
(18, 7,  650.00, '2027-05-22', NULL, 'aberta'),
(18, 8,  650.00, '2027-06-22', NULL, 'aberta'),
(18, 9,  650.00, '2027-07-22', NULL, 'aberta'),
(18, 10, 650.00, '2027-08-22', NULL, 'aberta'),
(19, 1, 180.00, '2026-02-10', '2026-02-10', 'paga'),
(20, 1, 430.00, '2026-03-02', '2026-03-02', 'paga');

-- ----------------------------------------------------------------------------
-- 6. Agenda (RN09 a RN11, RN20 a RN22)
--    Avaliação em um consultório fixo por dentista; tratamento com o dentista
--    da especialidade. Datas futuras: de 11/11 a 27/11/2026.
-- ----------------------------------------------------------------------------
INSERT INTO AGENDAMENTO (ID_AGENDAMENTO, ID_PACIENTE, ID_COLABORADOR, ID_CONSULTORIO, DT_HORA_INICIO, QT_DURACAO_MIN, TP_AGENDAMENTO, CD_STATUS, DS_OBSERVACAO, DT_RETORNO_PREVISTO) VALUES
-- 25 Antônia e 26 Osvaldo: ciclo completo de antes do recorte (avaliação, tratamento, alta, retorno)
(1,  25, 3, 3, '2026-02-10 10:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(2,  25, 3, 3, '2026-02-17 10:00:00', 40,  'tratamento', 'atendido',   NULL, NULL),
(3,  25, 1, 1, '2026-03-03 10:00:00', 30,  'alta',       'atendido',   NULL, '2026-09-03'),
(4,  25, 3, 3, '2026-09-03 10:00:00', 30,  'retorno',    'atendido',   NULL, NULL),
(5,  26, 6, 6, '2026-03-02 14:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(6,  26, 6, 6, '2026-03-09 14:00:00', 90,  'tratamento', 'atendido',   NULL, NULL),
(7,  26, 1, 1, '2026-04-14 14:00:00', 30,  'alta',       'atendido',   'Retorno previsto em outubro; ainda não agendado', '2026-10-14'),
-- 1 Mariana
(8,  1, 6, 6, '2026-08-03 09:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(9,  1, 2, 2, '2026-08-20 09:00:00', 120, 'tratamento', 'atendido',   NULL, NULL),
(10, 1, 3, 3, '2026-08-27 10:00:00', 40,  'tratamento', 'atendido',   NULL, NULL),
(11, 1, 2, 2, '2026-11-27 09:00:00', 60,  'tratamento', 'agendado',   'Instalação da coroa, aguardando laboratório', NULL),
-- 2 João Pedro
(12, 2, 3, 3, '2026-08-04 10:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(13, 2, 5, 5, '2026-08-13 14:00:00', 120, 'tratamento', 'atendido',   NULL, NULL),
(14, 2, 5, 5, '2026-08-27 14:00:00', 60,  'tratamento', 'atendido',   'Segunda sessão do canal', NULL),
(15, 2, 3, 3, '2026-11-19 10:00:00', 60,  'tratamento', 'confirmado', 'Instalação da coroa', NULL),
-- 3 Larissa
(16, 3, 1, 1, '2026-08-05 14:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(17, 3, 4, 4, '2026-08-14 09:00:00', 60,  'tratamento', 'atendido',   NULL, NULL),
(18, 3, 4, 4, '2026-09-14 09:00:00', 30,  'tratamento', 'atendido',   NULL, NULL),
(19, 3, 4, 4, '2026-10-14 09:00:00', 30,  'tratamento', 'atendido',   NULL, NULL),
-- 4 Antônio (recusou o orçamento)
(20, 4, 6, 6, '2026-08-10 09:30:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
-- 5 Beatriz (tratamento concluído e alta)
(21, 5, 3, 3, '2026-08-11 11:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(22, 5, 3, 3, '2026-08-18 11:00:00', 50,  'tratamento', 'atendido',   NULL, NULL),
(23, 5, 3, 3, '2026-08-25 11:00:00', 90,  'tratamento', 'atendido',   NULL, NULL),
(24, 5, 1, 1, '2026-09-15 11:00:00', 30,  'alta',       'atendido',   NULL, '2027-03-15'),
-- 6 Ricardo (1 parcela atrasada)
(25, 6, 1, 1, '2026-08-12 15:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(26, 6, 2, 2, '2026-08-26 09:00:00', 90,  'tratamento', 'atendido',   NULL, NULL),
(27, 6, 2, 2, '2026-11-25 09:00:00', 120, 'tratamento', 'agendado',   NULL, NULL),
-- 7 Carolina (em negociação)
(28, 7, 6, 6, '2026-08-17 10:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
-- 8 Fernando (bloqueado por 2 parcelas atrasadas, mas com consulta marcada)
(29, 8, 1, 1, '2026-08-18 09:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(30, 8, 2, 2, '2026-09-02 09:00:00', 120, 'tratamento', 'atendido',   NULL, NULL),
(31, 8, 2, 2, '2026-11-19 09:00:00', 60,  'tratamento', 'agendado',   NULL, NULL),
-- 9 Patrícia N. (aprovação parcial, concluído; a alta 35 foi feita por dentista comum, de propósito)
(32, 9, 3, 3, '2026-08-24 14:30:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(33, 9, 5, 5, '2026-09-03 14:00:00', 90,  'tratamento', 'atendido',   NULL, NULL),
(34, 9, 3, 3, '2026-09-17 14:30:00', 40,  'tratamento', 'atendido',   NULL, NULL),
(35, 9, 3, 3, '2026-10-20 14:30:00', 30,  'alta',       'atendido',   NULL, '2027-04-20'),
-- 10 Lucas (falta na manutenção e encaixe na semana seguinte)
(36, 10, 6, 6, '2026-08-25 16:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(37, 10, 4, 4, '2026-09-04 16:00:00', 60, 'tratamento', 'atendido',   NULL, NULL),
(38, 10, 4, 4, '2026-10-05 16:00:00', 30, 'tratamento', 'atendido',   NULL, NULL),
(39, 10, 4, 4, '2026-11-05 16:00:00', 30, 'tratamento', 'falta',      NULL, NULL),
(40, 10, 4, 4, '2026-11-12 16:00:00', 30, 'tratamento', 'agendado',   'Encaixe após a falta de 05/11', NULL),
-- 11 Sandra
(41, 11, 1, 1, '2026-09-01 10:30:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(42, 11, 3, 3, '2026-09-10 10:30:00', 60, 'tratamento', 'atendido',   NULL, NULL),
(43, 11, 1, 1, '2026-11-24 10:30:00', 90, 'tratamento', 'agendado',   'Instalação da prótese total', NULL),
-- 12 Gabriel (recusou)
(44, 12, 3, 3, '2026-09-02 09:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
-- 13 Juliana C. (cirurgia reagendada de 11/11 para 18/11)
(45, 13, 6, 6, '2026-09-08 11:00:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(46, 13, 2, 2, '2026-11-11 09:00:00', 120, 'tratamento', 'reagendado', 'Paciente pediu nova data', NULL),
(47, 13, 2, 2, '2026-11-18 09:00:00', 120, 'tratamento', 'confirmado', NULL, NULL),
-- 14 Marcelo (em negociação)
(48, 14, 1, 1, '2026-09-09 15:30:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
-- 15 Aline
(49, 15, 3, 3, '2026-09-15 10:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(50, 15, 3, 3, '2026-09-22 10:00:00', 50, 'tratamento', 'atendido',   NULL, NULL),
(51, 15, 3, 3, '2026-11-12 10:00:00', 30, 'tratamento', 'confirmado', 'Entrega da placa de bruxismo', NULL),
-- 16 Rodrigo (agendamento 54 atendido sem evolução, de propósito)
(52, 16, 6, 6, '2026-09-16 14:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(53, 16, 6, 6, '2026-09-23 14:00:00', 40, 'tratamento', 'atendido',   NULL, NULL),
(54, 16, 6, 6, '2026-10-07 14:00:00', 60, 'tratamento', 'atendido',   NULL, NULL),
-- 17 Vanessa L. (concluído, alta)
(55, 17, 1, 1, '2026-09-22 09:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(56, 17, 5, 5, '2026-09-29 09:00:00', 90, 'tratamento', 'atendido',   NULL, NULL),
(57, 17, 3, 3, '2026-10-13 09:00:00', 50, 'tratamento', 'atendido',   NULL, NULL),
(58, 17, 1, 1, '2026-11-05 09:00:00', 30, 'alta',       'atendido',   NULL, '2027-05-05'),
-- 18 Paulo Sérgio (em negociação)
(59, 18, 3, 3, '2026-09-23 16:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
-- 19 Isabela
(60, 19, 6, 6, '2026-09-29 10:30:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(61, 19, 4, 4, '2026-10-08 10:30:00', 60, 'tratamento', 'atendido',   NULL, NULL),
(62, 19, 4, 4, '2026-11-09 10:30:00', 30, 'tratamento', 'atendido',   NULL, NULL),
-- 20 Daniel (faltou à primeira avaliação e à restauração)
(63, 20, 1, 1, '2026-10-01 14:00:00', 30, 'avaliacao',  'falta',      NULL, NULL),
(64, 20, 1, 1, '2026-10-06 14:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(65, 20, 3, 3, '2026-10-14 14:00:00', 40, 'tratamento', 'atendido',   NULL, NULL),
(66, 20, 3, 3, '2026-10-28 14:00:00', 50, 'tratamento', 'falta',      NULL, NULL),
-- 21 Renata
(67, 21, 3, 3, '2026-10-07 09:30:00', 30,  'avaliacao',  'atendido',   NULL, NULL),
(68, 21, 5, 5, '2026-10-15 09:30:00', 120, 'tratamento', 'atendido',   NULL, NULL),
(69, 21, 3, 3, '2026-11-26 09:30:00', 60,  'tratamento', 'agendado',   'Instalação da coroa', NULL),
-- 22 Felipe
(70, 22, 6, 6, '2026-10-13 15:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(71, 22, 6, 6, '2026-10-21 15:00:00', 40, 'tratamento', 'atendido',   NULL, NULL),
(72, 22, 6, 6, '2026-11-04 15:00:00', 60, 'tratamento', 'atendido',   NULL, NULL),
-- 23 Cláudia (agendamento 74 sobrepõe o 47 no consultório 2 e na agenda da Dra. Ana, de propósito)
(73, 23, 1, 1, '2026-10-20 10:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL),
(74, 23, 2, 2, '2026-11-18 10:00:00', 90, 'tratamento', 'agendado',   'Enxerto ósseo', NULL),
-- 24 Henrique (avaliado em 03/11)
(75, 24, 3, 3, '2026-11-03 11:00:00', 30, 'avaliacao',  'atendido',   NULL, NULL);

-- Itens executados (ou previstos) em cada consulta de tratamento (RN12)
-- O agendamento 57 ficou sem item de propósito (o item 17-2 consta como concluído).
INSERT INTO AGENDAMENTO_ITEM (ID_AGENDAMENTO, ID_ORCAMENTO, NR_ITEM) VALUES
(2, 25, 1),
(6, 26, 1), (6, 26, 2),
(9, 1, 1), (10, 1, 3), (11, 1, 2),
(13, 2, 1), (14, 2, 1), (15, 2, 2),
(17, 3, 1), (18, 3, 2), (19, 3, 3),
(22, 5, 1), (23, 5, 2), (23, 5, 3),
(26, 6, 1), (27, 6, 2),
(30, 8, 1), (31, 8, 2),
(33, 9, 1), (34, 9, 3),
(37, 10, 1), (38, 10, 2), (39, 10, 3), (40, 10, 3),
(42, 11, 2), (42, 11, 3), (43, 11, 1),
(46, 13, 1), (47, 13, 1),
(50, 15, 1), (51, 15, 2),
(53, 16, 1), (54, 16, 2),
(56, 17, 1),
(61, 19, 1), (62, 19, 2),
(65, 20, 1), (66, 20, 2),
(68, 21, 1), (69, 21, 2),
(71, 22, 1), (72, 22, 2),
(74, 23, 3);

-- ----------------------------------------------------------------------------
-- 7. Evolução clínica (RN16): uma por consulta atendida.
--    Cada INSERT aqui dispara o gatilho que grava em LOG_ALTERACAO.
--    O agendamento 54 fica sem evolução de propósito.
-- ----------------------------------------------------------------------------
INSERT INTO EVOLUCAO_CLINICA (ID_AGENDAMENTO, DT_REGISTRO, DS_EVOLUCAO, NR_DENTE, DS_PROXIMOS_PASSOS) VALUES
(2,  '2026-02-17 10:45:00', 'Profilaxia realizada. Orientação de escovação e fio dental.', NULL, 'Consulta de alta.'),
(3,  '2026-03-03 10:30:00', 'Alta: gengiva sem sangramento, sem cárie ativa.', NULL, 'Retorno em 6 meses.'),
(4,  '2026-09-03 10:30:00', 'Retorno: boa higiene, sem novas lesões.', NULL, 'Novo retorno em 6 meses, se desejar.'),
(6,  '2026-03-09 15:35:00', 'Profilaxia e restauração em resina no 36 concluídas.', 36, 'Consulta de alta.'),
(7,  '2026-04-14 14:30:00', 'Alta: restauração íntegra, sem sensibilidade.', 36, 'Retorno em 6 meses.'),
(9,  '2026-08-20 11:05:00', 'Instalação de implante no 36 sem intercorrências. Medicação e repouso orientados.', 36, 'Retirar pontos em 7 dias; moldagem da coroa após 4 meses.'),
(10, '2026-08-27 10:45:00', 'Profilaxia realizada; pontos do 36 retirados, cicatrização boa.', 36, 'Aguardar osseointegração.'),
(13, '2026-08-13 16:05:00', 'Abertura e instrumentação dos canais do 46; medicação intracanal.', 46, 'Obturação na próxima sessão.'),
(14, '2026-08-27 15:05:00', 'Obturação dos canais do 46 concluída.', 46, 'Moldagem para coroa de porcelana.'),
(17, '2026-08-14 10:05:00', 'Instalação de aparelho fixo nas duas arcadas.', NULL, 'Manutenção em 30 dias.'),
(18, '2026-09-14 09:35:00', 'Manutenção: troca de ligaduras e ajuste do arco.', NULL, 'Manutenção em 30 dias.'),
(19, '2026-10-14 09:35:00', 'Manutenção: troca de ligaduras; alinhamento evoluindo bem.', NULL, 'Manutenção em 30 dias; novo orçamento para as próximas.'),
(22, '2026-08-18 11:55:00', 'Restauração em resina no 25 concluída.', 25, 'Restauração do 14 e profilaxia na próxima.'),
(23, '2026-08-25 12:35:00', 'Restauração em resina no 14 e profilaxia concluídas. Plano finalizado.', 14, 'Consulta de alta com o diretor clínico.'),
(24, '2026-09-15 11:30:00', 'Alta: restaurações íntegras, higiene adequada.', NULL, 'Retorno em 6 meses.'),
(26, '2026-08-26 10:35:00', 'Enxerto ósseo na região do 11 realizado.', 11, 'Aguardar 3 meses para o implante.'),
(30, '2026-09-02 11:05:00', 'Instalação de implante no 46 sem intercorrências.', 46, 'Moldagem da coroa após osseointegração.'),
(33, '2026-09-03 15:35:00', 'Tratamento de canal do 21 concluído em sessão única.', 21, 'Paciente recusou a coroa; acompanhar.'),
(34, '2026-09-17 15:15:00', 'Profilaxia realizada. Plano finalizado.', NULL, 'Consulta de alta.'),
(35, '2026-10-20 15:05:00', 'Alta: 21 sem sintomas, higiene boa.', 21, 'Retorno em 6 meses.'),
(37, '2026-09-04 17:05:00', 'Instalação de aparelho fixo.', NULL, 'Manutenção em 30 dias.'),
(38, '2026-10-05 16:35:00', 'Manutenção: ajuste do arco.', NULL, 'Manutenção em 30 dias.'),
(42, '2026-09-10 11:35:00', 'Extração simples do 41 e do 31. Hemostasia adequada.', 41, 'Moldagem para prótese total após cicatrização.'),
(50, '2026-09-22 10:55:00', 'Restauração em resina no 36 concluída. Moldagem para placa de bruxismo.', 36, 'Entrega da placa quando o laboratório concluir.'),
(53, '2026-09-23 14:45:00', 'Profilaxia realizada.', NULL, 'Clareamento na próxima.'),
(56, '2026-09-29 10:35:00', 'Tratamento de canal do 12 concluído.', 12, 'Restauração do 12.'),
(57, '2026-10-13 09:55:00', 'Restauração em resina no 12 concluída. Plano finalizado.', 12, 'Consulta de alta.'),
(58, '2026-11-05 09:30:00', 'Alta: 12 sem sintomas, restauração íntegra.', 12, 'Retorno em 6 meses.'),
(61, '2026-10-08 11:35:00', 'Instalação de aparelho fixo.', NULL, 'Manutenção em 30 dias.'),
(62, '2026-11-09 11:05:00', 'Manutenção: troca de ligaduras.', NULL, 'Manutenção em 30 dias.'),
(65, '2026-10-14 14:45:00', 'Profilaxia realizada.', NULL, 'Restauração do 46.'),
(68, '2026-10-15 11:35:00', 'Tratamento de canal do 16 concluído. Moldagem para coroa.', 16, 'Instalação da coroa quando o laboratório concluir.'),
(71, '2026-10-21 15:45:00', 'Profilaxia realizada.', NULL, 'Clareamento na próxima.'),
(72, '2026-11-04 16:05:00', 'Clareamento em consultório concluído. Plano finalizado.', NULL, 'Consulta de alta.');

-- Evolução das avaliações atendidas: o registro aponta o orçamento gerado no mesmo dia
INSERT INTO EVOLUCAO_CLINICA (ID_AGENDAMENTO, DT_REGISTRO, DS_EVOLUCAO, NR_DENTE, DS_PROXIMOS_PASSOS)
SELECT A.ID_AGENDAMENTO,
       A.DT_HORA_INICIO + INTERVAL A.QT_DURACAO_MIN MINUTE,
       CONCAT('Avaliação inicial: exame clínico e anamnese. Plano de tratamento no orçamento ', O.ID_ORCAMENTO, '.'),
       NULL,
       'Negociação do orçamento com o comercial.'
FROM AGENDAMENTO A
JOIN ORCAMENTO O ON O.ID_PACIENTE = A.ID_PACIENTE
               AND O.DT_EMISSAO = DATE(A.DT_HORA_INICIO)
WHERE A.TP_AGENDAMENTO = 'avaliacao'
  AND A.CD_STATUS = 'atendido';

-- ----------------------------------------------------------------------------
-- 8. Pedidos ao laboratório da clínica (RN15)
--    Pedido 2: prazo venceu em 19/10 e a peça ainda está em produção.
-- ----------------------------------------------------------------------------
INSERT INTO PEDIDO_LABORATORIO (ID_PEDIDO, ID_PACIENTE, ID_COLABORADOR, DT_SOLICITACAO, DS_PECA, DT_PRAZO_ENTREGA, DT_ENTREGA, CD_STATUS) VALUES
(1, 2,  3, '2026-10-14', 'Coroa de porcelana, dente 46',    '2026-10-28', '2026-10-27', 'entregue'),
(2, 8,  2, '2026-10-05', 'Coroa sobre implante, dente 46',  '2026-10-19', NULL,         'em_producao'),
(3, 11, 1, '2026-10-10', 'Prótese total superior',          '2026-11-10', NULL,         'pronto'),
(4, 15, 3, '2026-10-21', 'Placa de bruxismo',               '2026-11-04', '2026-11-03', 'entregue'),
(5, 21, 3, '2026-11-04', 'Coroa de porcelana, dente 16',    '2026-11-18', NULL,         'solicitado'),
(6, 1,  2, '2026-11-06', 'Coroa sobre implante, dente 36',  '2026-11-20', NULL,         'em_producao');

-- ----------------------------------------------------------------------------
-- Conferência: quantas linhas entraram em cada tabela
-- ----------------------------------------------------------------------------
SELECT 'PACIENTE' AS tabela, COUNT(*) AS linhas FROM PACIENTE
UNION ALL SELECT 'TELEFONE_PACIENTE', COUNT(*) FROM TELEFONE_PACIENTE
UNION ALL SELECT 'COLABORADOR', COUNT(*) FROM COLABORADOR
UNION ALL SELECT 'ESPECIALIDADE', COUNT(*) FROM ESPECIALIDADE
UNION ALL SELECT 'COLABORADOR_ESPECIALIDADE', COUNT(*) FROM COLABORADOR_ESPECIALIDADE
UNION ALL SELECT 'CONSULTORIO', COUNT(*) FROM CONSULTORIO
UNION ALL SELECT 'PROCEDIMENTO', COUNT(*) FROM PROCEDIMENTO
UNION ALL SELECT 'ORCAMENTO', COUNT(*) FROM ORCAMENTO
UNION ALL SELECT 'ITEM_ORCAMENTO', COUNT(*) FROM ITEM_ORCAMENTO
UNION ALL SELECT 'CONTRATO', COUNT(*) FROM CONTRATO
UNION ALL SELECT 'PARCELA', COUNT(*) FROM PARCELA
UNION ALL SELECT 'AGENDAMENTO', COUNT(*) FROM AGENDAMENTO
UNION ALL SELECT 'AGENDAMENTO_ITEM', COUNT(*) FROM AGENDAMENTO_ITEM
UNION ALL SELECT 'EVOLUCAO_CLINICA', COUNT(*) FROM EVOLUCAO_CLINICA
UNION ALL SELECT 'PEDIDO_LABORATORIO', COUNT(*) FROM PEDIDO_LABORATORIO
UNION ALL SELECT 'LOG_ALTERACAO', COUNT(*) FROM LOG_ALTERACAO;
