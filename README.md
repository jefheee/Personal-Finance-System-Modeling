#  Sistema de Finanças Pessoais - Modelagem e Automação de Dados

Este projeto apresenta a modelagem técnica completa e a implementação de scripts de automação para um ecossistema de gestão financeira pessoal. A solução substitui métodos manuais ineficientes por um banco de dados relacional estruturado, incluindo um fluxo completo de processamento de dados legados.

##  Arquitetura do Projeto
O sistema foi projetado para garantir rastreabilidade e integridade total das informações financeiras. A arquitetura divide-se em:
* [cite_start]**Modelagem UML:** Diagramas de Casos de Uso, Classes e Sequência que mapeiam o comportamento do software e as regras de negócio[cite: 2, 4].
* [cite_start]**Arquitetura Relacional:** Um modelo Entidade-Relacionamento (DER) normalizado e implementado em **PostgreSQL**, utilizando chaves estrangeiras para garantir a consistência entre contas, categorias e lançamentos[cite: 4].
* [cite_start]**Engenharia de Requisitos:** Definição rigorosa de Requisitos Funcionais (como cadastro de lançamentos e geração de dashboards) e Não Funcionais (como o uso do SGBD PostgreSQL)[cite: 1, 4].

##  Diferenciais Técnicos e Fluxo de ETL
O ponto central desta implementação é o script de automação de dados (`script_import_scv_completo.sql`), que realiza o processo de **ETL** para migração de planilhas legadas:

1. **Camada de Staging:** Criação de tabelas temporárias para recepção de dados brutos via CSV, evitando a contaminação da tabela de produção durante o processamento.
2. **Transformação de Dados:** Scripts inteligentes que convertem dados de texto puro em referências relacionais (IDs), mapeando nomes de contas e formas de pagamento para seus respectivos registros no banco.
3. **Limpeza e Padronização:** Tratamento automático de inconsistências e renomeação de campos para alinhar dados históricos ao novo padrão do sistema.
4. **Carga Final:** Migração segura da tabela de staging para a tabela final `en_lancamento`, garantindo que apenas dados válidos sejam persistidos.

##  Detalhes da Implementação (PostgreSQL)
* **Integridade Referencial:** Uso intensivo de `REFERENCES` com políticas de `ON DELETE SET NULL` para evitar perda acidental de histórico.
* **Constraints de Validação:** Implementação de `CHECK CONSTRAINTS` para garantir que valores monetários nunca sejam negativos e que os tipos de lançamentos sejam restritos a 'DESPESAS' ou 'RECEITAS'.
* **Tipagem Dinâmica:** Uso de comandos `ALTER COLUMN` com casting direto (`TYPE INT USING ...`) para otimizar o desempenho do banco após a importação.

##  Interface e Usabilidade
* [cite_start]**Dashboards Analíticos:** Prototipagem de visualizações com gráficos de pizza e barras para análise imediata de saldos e despesas por categoria[cite: 1, 4].
* [cite_start]**Formulários Estruturados:** Telas de cadastro desenhadas para facilitar a entrada de dados, reduzindo a carga cognitiva do usuário[cite: 1, 4].

---
**Autores:** Jefherson Luiz, Matheus Artismo, Guilherme Meira, William Gomes Reis e Gabriel Salazar.
