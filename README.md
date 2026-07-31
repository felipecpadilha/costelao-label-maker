# Costelao Label Maker

Aplicativo Flutter para cadastro, consulta e impressao de etiquetas de alimentos.

O foco atual do projeto e:

- impressao de etiquetas de validade por produto;
- impressao de rotulo livre (texto digitado pelo usuario);
- gestao de produtos, responsaveis e fichas tecnicas;
- backup e restauracao local em JSON.

## Estado atual do projeto

Funcionalidades implementadas neste momento:

1. Home com botoes grandes para acesso rapido:
- ETIQUETAS
- ROTULO
- RECEITAS

2. Impressao de etiquetas de validade:
- selecao de produto;
- selecao de responsavel;
- quantidade de copias;
- data de validade dinamica (quando o produto exige);
- selecao de impressora Bluetooth pareada;
- envio de comando TSPL para impressora termica.

3. Impressao de rotulo livre:
- campo de texto livre;
- selecao de impressora Bluetooth pareada;
- impressao centralizada com fonte tamanho 2;
- quebra de linha automatica e ajuste vertical do bloco de texto.

4. Cadastros:
- produtos (CRUD);
- responsaveis (CRUD);
- fichas tecnicas com visualizacao e edicao.

5. Configuracoes:
- exportar backup do banco para JSON em Downloads;
- restaurar backup via seletor de arquivo;
- refresh de informacoes do ultimo backup.

## Rotas principais

Rotas atualmente registradas:

- /
- /impressao
- /impressao/completar
- /impressao/rotulo
- /fichas-tecnicas
- /fichas-tecnicas/visualizar
- /fichas-tecnicas/detalhe
- /fichas-tecnicas/form
- /produtos
- /responsaveis
- /configuracoes

## Stack tecnica

- Flutter / Dart
- go_router (navegacao)
- flutter_bloc (estado)
- sqflite + sqflite_common_ffi / web (persistencia local)
- print_bluetooth_thermal (impressao Bluetooth)
- permission_handler (permissoes)
- image_picker e flutter_quill (fluxos de fichas tecnicas)
- file_picker (restauracao de backup)

## Arquitetura e estrutura

Organizacao por features em lib/src, com separacao em camadas quando aplicavel:

- core
  - database
  - router
  - theme
- features
  - home
  - impressao
  - products
  - responsaveis
  - fichas_tecnicas
  - labels
  - settings

## Impressao TSPL (resumo)

O modulo de impressao trabalha com um servico abstrato e implementacao por plataforma:

- listagem de impressoras Bluetooth pareadas;
- conexao por MAC address;
- envio de comandos TSPL em ASCII;
- sanitizacao de texto para evitar caracteres nao suportados por algumas impressoras.

## Como rodar

Pre-requisitos:

- Flutter SDK instalado
- dispositivo Android (recomendado para teste de Bluetooth)

Comandos:

```bash
flutter pub get
flutter run
```

Analise e testes:

```bash
flutter analyze
flutter test
```

## Observacoes

- O projeto possui alguns avisos de analise (lint/deprecations) ainda pendentes em arquivos especificos, sem bloquear compilacao.
- Para impressao Bluetooth real, valide permissao do app, Bluetooth ativo e impressora previamente pareada no Android.
