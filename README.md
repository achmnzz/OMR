## Instruções
  Como já estou enviando com os modelos de gabarito e com as imagens de FR para teste prontas na pasta Folhas_Resposta, para executar basta rodar a função `corrigir_provas`

  Opcionalmente, pode rodar a função `gera_folha_resposta_e_gabarito("X", "X", "folha_resposta.png")` para gerar uma folha resposta em branco para preenchimento manual.

### Resposta esperada:

  ```xml
  K>> corrigir_provas
  Warning: Nenhum círculo na região válida. 
  > In ler_folha_resposta_retificada (line 74)
  In ler_folha_resposta_por_foto (line 133)
  In corrigir_provas (line 17)
  In matlab.internal.getSettingsRoot (line 2) 
  Prova FR1 acertou 25 questões da prova A 
  Prova FR2 acertou 10 questões da prova B 
  Prova FR3 acertou 40 questões da prova C 
  Prova FR4 acertou 50 questões da prova D 
  Prova FR5 não leu corretamente, tente novamente com menos distorções
  ```

## Estrutura de Pastas

```text
.
├─ Folhas_Resposta/
│  ├─ fr1.png
│  ├─ fr2.png
│  ├─ fr3.png
│  ├─ fr4.png
│  └─ fr5.png
│      └─ (fotos/scans das folhas de resposta dos alunos)
│
├─ Gabaritos/
│  ├─ gabarito_A.png
│  ├─ gabarito_B.png
│  ├─ gabarito_C.png
│  └─ gabarito_D.png
│      └─ (imagens dos gabaritos oficiais de cada tipo de prova)
│
├─ Metodos_Auxiliares/
│  ├─ conta_circulos_preenchidos.m
│  │    └─ funções para contar/detectar bolhas preenchidas
│  ├─ criar_gabaritos.m
│  │    └─ script/função para montar a estrutura de gabaritos (ex.: gabaritos.mat)
│  ├─ gera_folha_resposta_e_gabarito.m
│  │    └─ gera simultaneamente folha de resposta modelo + gabarito correspondente
│  └─ gera_multiplos_gabaritos.m
│       └─ automatiza a criação de vários gabaritos/tipos de prova
│
├─ Output/
│  └─ Resultados/
│     ├─ corrigir_provas.m
│     │    └─ script principal de correção das provas (lê folhas e aplica gabaritos)
│     ├─ gabaritos.mat
│     │    └─ estrutura MATLAB com os gabaritos de cada tipo (A, B, C, D, ...)
│     ├─ ler_folha_resposta_por_foto.m
│     │    └─ lê uma foto da folha, corrige perspectiva e extrai respostas
│     ├─ ler_folha_resposta_por_foto.asv
│     │    └─ arquivo de autosave do MATLAB (backup automático, pode ser ignorado)
│     └─ ler_folha_resposta_retificada.m
│          └─ versão que lê a folha já retificada (sem distorção) e extrai as marcas
