--------------------------------------------------------------------------------------------
-- Script para importar a tabela excel (Finanças Pessoais Dados.xlsx) para o banco de dados. 
-- A tabela primeiro precisa ser salva como um arquivo .csv no Google Sheets.
-- Criado por Guilherme Martins Meira.
--------------------------------------------------------------------------------------------

--------------------------------------------------
-- 1) Começando criando as tabelas finais do banco.
--------------------------------------------------

CREATE TABLE en_conta (
  conta_id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL
);

CREATE TABLE en_categoria (
  categoria_id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE en_forma_pagamento (
  forma_pagamento_id SERIAL PRIMARY KEY,
  nome VARCHAR(50) NOT NULL UNIQUE
);

-- criar a tabela principal de Lancamento.
CREATE TABLE en_lancamento (
  lancamento_id SERIAL PRIMARY KEY,
  data_lancamento DATE NOT NULL,
  tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('DESPESAS','RECEITAS')),
  categoria_id INT REFERENCES en_categoria(categoria_id) ON DELETE SET NULL,
  descricao VARCHAR(255),
  conta_id INT REFERENCES en_conta(conta_id) ON DELETE SET NULL,
  forma_pagamento_id INT REFERENCES en_forma_pagamento(forma_pagamento_id) ON DELETE SET NULL,
  valor NUMERIC(12,2) NOT NULL CHECK (valor >= 0),
  conciliado BOOLEAN DEFAULT FALSE
);

-------------------------------------------------------------------------------------------
-- 2) Depois é criado a tabela temporaria para importar o csv, todas as variáveis como TEXT
-------------------------------------------------------------------------------------------

CREATE TABLE lancamento_import_csv (
	data_lancamento TEXT,
	tipo TEXT,
	categoria TEXT,
	descricao TEXT,
	conta TEXT,
	forma_pagamento TEXT,
	valor TEXT,
	conciliado TEXT
);


COPY lancamento_import_csv from 'C:/tabela.csv' -- local aqui esta no "C:/" diretamente porque é mais fácil de acessar.
DELIMITER ','
CSV HEADER;

-----------------------------------------------------------------------------------
-- 3) Agora é necessário converter os arquivos em TEXT para os devidos valores SQL.
-----------------------------------------------------------------------------------

----------------------------------------
-- Converter "data_lancamento" para DATE
----------------------------------------

-- 1: altera o formato para o do DATE ("12/30/2023" -> "2023-12-30")
UPDATE lancamento_import_csv
SET data_lancamento = TO_DATE(data_lancamento, 'MM/DD/YYYY')
WHERE data_lancamento LIKE '%/%/%';

-- 2: converte de TEXT para DATE
ALTER TABLE lancamento_import_csv
ALTER COLUMN data_lancamento TYPE DATE USING data_lancamento::DATE;

---------------------------------
-- Converter "valor" para NUMERIC
---------------------------------

-- 1: tira os pontos em valores na casa do milhar ("R$ 1.200,00" -> "R$ 1200,00")
UPDATE lancamento_import_csv
SET valor = REPLACE(valor, '.', '')
WHERE valor LIKE '%.%' AND valor LIKE '%R$%';

-- 2: remove o R$ e muda a , para . ("R$ 1200,00" -> "1200.00")
UPDATE lancamento_import_csv
SET valor = REPLACE(REPLACE(valor, 'R$', ''), ',', '.');

-- 3: converte de TEXT para NUMERIC
ALTER TABLE lancamento_import_csv
ALTER COLUMN valor TYPE DECIMAL(10, 2) USING valor::NUMERIC(10,2);

--------------------------------------
-- Converter "conciliado" para BOOLEAN
--------------------------------------

-- 1: usa CASE para mudar o "S" e "N" para "true" e "false"
UPDATE lancamento_import_csv
SET conciliado = CASE
                    WHEN conciliado = 'S' THEN TRUE
                    WHEN conciliado = 'N' THEN FALSE
                 END;

-- 2: converte de TEXT para BOOLEAN
ALTER TABLE lancamento_import_csv
ALTER COLUMN conciliado TYPE BOOLEAN USING conciliado::BOOLEAN;

------------------------------------------------------------------------
-- 4) Inserir valores que repetem em suas devidas tabelas (Normalização)
------------------------------------------------------------------------

-- inserir as categorias da tabela importada "lancamento_import_csv" para a tabela en_categoria

INSERT INTO en_categoria (nome)
SELECT DISTINCT categoria
FROM lancamento_import_csv
WHERE categoria IS NOT NULL;

-- inserir as contas da tabela importada "lancamento_import_csv" para a tabela en_conta

INSERT INTO en_conta (nome)
SELECT DISTINCT conta
FROM lancamento_import_csv
WHERE conta IS NOT NULL;

-- inserir as formas de pagamento da tabela importada "lancamento_import_csv" para a tabela en_forma_pagamento (Normalização)

INSERT INTO en_forma_pagamento (nome)
SELECT DISTINCT forma_pagamento
FROM lancamento_import_csv
WHERE forma_pagamento IS NOT NULL;

-----------------------------------------------------------------------------
-- 5) Atualizar a tabela temporária para usar os ids das tabelas normalizadas
-----------------------------------------------------------------------------

------------
-- CATEGORIA
------------

-- 1: muda o nome da categoria para o id da categoria na "en_categoria"
UPDATE lancamento_import_csv l
SET categoria = c.categoria_id
FROM en_categoria c
WHERE l.categoria = c.nome;

-- 2: muda o tipo de TEXT para INT
ALTER TABLE lancamento_import_csv
ALTER COLUMN categoria TYPE INT USING categoria::INT;

------------
-- CONTA
------------

-- 1: muda o nome da conta para o id da conta na "en_conta"
UPDATE lancamento_import_csv l
SET conta = co.conta_id
FROM en_conta co
WHERE l.conta = co.nome;

-- 2: muda o tipo de TEXT para INT
ALTER TABLE lancamento_import_csv
ALTER COLUMN conta TYPE INT USING conta::INT;

-------------------
-- FORMA PAGAMENTO
-------------------

-- 1: muda o nome da forma_pagamento para o id da forma_pagamento na "en_forma_pagamento"
UPDATE lancamento_import_csv l
SET forma_pagamento = f.forma_pagamento_id
FROM en_forma_pagamento f
WHERE l.forma_pagamento = f.nome;

-- 2: muda o tipo de TEXT para INT
ALTER TABLE lancamento_import_csv
ALTER COLUMN forma_pagamento TYPE INT USING forma_pagamento::INT;

-------------------------------------------------------------------------------------------------------------------------
-- 6) Finalmente, copia os dados da tabela temporaria para a tabela final en_lancamento, e a tabela temporaria é deletada
-------------------------------------------------------------------------------------------------------------------------

INSERT INTO en_lancamento (data_lancamento, tipo, categoria_id, descricao, conta_id, forma_pagamento_id, valor, conciliado)
SELECT data_lancamento, tipo, categoria, descricao, conta, forma_pagamento, valor, conciliado
FROM lancamento_import_csv;

TRUNCATE TABLE lancamento_import_csv;
DROP TABLE lancamento_import_csv;