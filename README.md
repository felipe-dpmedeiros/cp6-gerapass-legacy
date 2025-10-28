# 🔒 GeraPass: Gerador de Senhas

Feito por:
Felipe Della Paschoa de Medeiros - 98157
Gabriel Iruela del Pozo - 551425

Um aplicativo completo em Flutter para gerar e gerenciar senhas com segurança, utilizando Firebase para autenticação e armazenamento no Cloud Firestore.

<img width="658" height="911" alt="image" src="https://github.com/user-attachments/assets/11914804-7945-48b6-a143-253d1f67514d" /> <img width="657" height="914" alt="image" src="https://github.com/user-attachments/assets/2ef70c0c-67d4-47ec-ace3-97168442e249" />

## Features Principais

* **Autenticação de Usuários:** Login e Registro completos com Email/Senha via **Firebase Auth**.
* **Rotas Protegidas:** Utiliza um `AuthGuard` para garantir que apenas usuários logados acessem a tela principal.
* **Fluxo de Onboarding:** Uma tela de introdução (intro) é exibida apenas no primeiro acesso do usuário, controlada via `shared_preferences`.
* **Geração de Senhas:** Gera senhas seguras consumindo a API pública `passwordwolf.com`.
    * Permite configurar tamanho, e inclusão de letras maiúsculas/minúsculas, números e símbolos.
    * Inclui tratamento de CORS para a plataforma Web (`kIsWeb`).
* **Armazenamento Seguro:** Salva as senhas geradas no **Cloud Firestore**, associadas a um rótulo.
* **Gerenciamento de Senhas:**
    * Lista todas as senhas salvas.
    * Permite visualizar/ocultar a senha.
    * Permite excluir senhas.
    * Permite copiar a senha para a área de transferência.
* **UI Moderna:** Utiliza animações `Lottie` para telas de carregamento, intro e listas vazias.

---

## Tecnologias Utilizadas

* **Flutter** & **Dart**
* **Firebase**
    * Firebase Authentication
    * Cloud Firestore
* **`http`**: Para requisições à API externa de geração de senhas.
* **`shared_preferences`**: Para salvar localmente a preferência de exibição da tela de Intro.
* **`lottie`**: Para as animações.

---

## Estrutura do Projeto (Arquivos Fornecidos)

Aqui está uma breve descrição dos principais arquivos que compõem o núcleo do aplicativo:

* `main.dart`: Ponto de entrada do app. Inicializa o Firebase e configura o `MaterialApp`, definindo a rota inicial e o gerenciador de rotas.
* `routes.dart`: Centraliza a definição de todas as rotas nomeadas (`splash`, `intro`, `home`, `password`) e suas respectivas telas.
* `auth_guard.dart`: Um widget de "guarda" que escuta o `authStateChanges()` do Firebase. Se o usuário não estiver logado, ele é redirecionado para a `LoginScreen`, protegendo as rotas privadas.
* `splash_screen.dart`: Tela de carregamento inicial. Verifica (usando `SettingsRepository`) se o usuário já viu a intro para decidir se navega para `/intro` ou `/home`.
* `intro_screen.dart`: Tela de onboarding com `PageView` e animações Lottie. Salva a preferência do usuário para não ser exibida novamente.
* `login_screen.dart`: Tela de autenticação que permite ao usuário Entrar (`signIn`) ou Registrar (`signUp`) com email e senha.
* `home_screen.dart`: A tela principal do app, protegida pelo `AuthGuard`. Exibe a lista de senhas (`SenhasList`) salvas no Firestore e permite o logout.
    * `SenhasList` (dentro de `home_screen.dart`): Um `StreamBuilder` que escuta a coleção `passwords` do Firestore em tempo real, exibindo a lista e permitindo mostrar/ocultar e excluir itens.
* `NewPasswordScreen.dart`: Tela onde o usuário configura (tamanho, caracteres) e gera uma nova senha. Também é responsável por salvar a senha gerada no Firestore.
* `settings_repository.dart`: Uma classe que abstrai o uso do `shared_preferences` para salvar e ler configurações locais, como a flag `show_intro`.
* `firebase_options_web.dart`: Arquivo de configuração contendo as chaves do projeto Firebase para a plataforma Web.

---

## Como Executar

1.  **Configure o Firebase:**
    * Crie um projeto no console do Firebase.
    * Adicione um aplicativo Web ao seu projeto e copie as credenciais.
    * Substitua o conteúdo de `firebase_options_web.dart` pelas suas credenciais.
    * No console do Firebase, ative os serviços de **Authentication** (Email/Senha) e **Cloud Firestore**.

2.  **Instale as dependências do Flutter:**
    ```bash
    flutter pub get
    ```

3.  **Execute o aplicativo:**
    ```bash
    flutter run -d chrome
    ```
