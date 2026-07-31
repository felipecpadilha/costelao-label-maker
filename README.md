# Costelao Label Maker

Aplicativo para criacao e impressao de etiquetas de validade para alimentos armazenados.

O objetivo do app e facilitar a identificacao de produtos com data de armazenamento e data de validade, padronizando o processo de etiquetagem e reduzindo erros operacionais.

## Funcionalidades

### 1) Criacao da etiqueta

Fluxo esperado:

1. O usuario seleciona um produto cadastrado.
2. O usuario seleciona o responsavel pelo produto.
3. O usuario informa quantas etiquetas deseja imprimir.
4. O app preenche automaticamente:
	 - Data de armazenamento (data atual)
	 - Data de validade (data de armazenamento + validade do produto em dias)
5. A etiqueta e enviada para impressao em impressora Bluetooth compativel com TSPL.

Campos principais da etiqueta:

- Produto
- Responsavel
- Data de armazenamento
- Data de validade
- Quantidade de etiquetas

### 2) Cadastro de produtos

O app permite criar, editar e remover produtos.

Cada produto possui:

- Nome
- Tempo de validade (em dias)

### 3) Cadastro de responsaveis

O app permite criar, editar e remover responsaveis (usuarios).

Cada responsavel possui:

- Nome

## Stack Tecnica

- Flutter + Dart
- Roteamento: go_router
- Estado: flutter_bloc
- Persistencia local: SQLite (sqflite)
- Arquitetura: Clean Architecture por feature

## Estrutura do Projeto

Estrutura principal em lib/src:

- core
	- router
	- database
	- theme
- features
	- labels
		- domain
		- data
		- presentation

## Banco de Dados Local

Persistencia local com SQLite para funcionamento offline.

Entidades principais previstas:

- products
- users (responsaveis)

Observacao:

- Etiquetas nao sao persistidas no banco. O app persiste apenas produtos e responsaveis.

## Sugestoes de Bibliotecas

### SQLite

- Atual: sqflite (ja adotado)
- Opcional para evolucao: drift (melhor tipagem e migracoes mais robustas)

### Bluetooth / Impressao TSPL

Para impressoras TSPL via Bluetooth, opcoes comuns no ecossistema Flutter:

- flutter_blue_plus
	- Maior controle de conexao BLE/classico (quando suportado)
	- Bom para envio de comandos TSPL em baixo nivel
- print_bluetooth_thermal
	- Mais simples para cenarios de impressao termica
	- Verificar compatibilidade com o modelo exato da impressora TSPL

Recomendacao pratica:

1. Validar o protocolo suportado pela impressora (BLE vs Bluetooth classico).
2. Criar um modulo de impressao desacoplado na camada de infraestrutura.
3. Padronizar templates TSPL para manter consistencia das etiquetas.

## Como Rodar o Projeto

Prerequisitos:

- Flutter SDK instalado
- Dispositivo Android/iOS ou emulador

Comandos:

```bash
flutter pub get
flutter run
```

Qualidade de codigo:

```bash
flutter analyze
flutter test
```

## Status Atual

Base inicial criada com estrutura arquitetural e modulo inicial de etiquetas.

Proximos incrementos sugeridos:

1. CRUD completo de produtos.
2. CRUD completo de responsaveis.
3. Geracao da data de validade automatica no fluxo de impressao.
4. Integracao com impressora Bluetooth TSPL.
