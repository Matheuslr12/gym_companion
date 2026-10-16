# Gym Companion

Gym Companion é um aplicativo mobile desenvolvido em **Flutter** para organizar treinos de academia, registrar exercícios e acompanhar a evolução semanal.

O aplicativo possui interface escura, navegação por abas e foco em uso rápido durante o treino.

## Funcionalidades

- Criar treinos personalizados, como Push, Pull, Pernas, Full Body e outros grupos musculares.
- Adicionar exercícios com nome, região do corpo, músculo primário, músculo secundário, séries e repetições.
- Visualizar os exercícios de cada treino.
- Iniciar um treino pela tela inicial.
- Registrar a execução dos treinos por meio da tela de execução.
- Acompanhar o resumo semanal de treinos realizados e séries concluídas.
- Receber notificações locais.
- Excluir treinos e exercícios com confirmação.

## Telas

| Aba | Descrição |
|---|---|
| Início | Seleciona um treino, inicia a sessão e mostra o resumo da semana. |
| Treinos | Cria, visualiza, gerencia e exclui treinos e exercícios. |
| Relatórios | Área destinada ao acompanhamento de cargas, volume e progresso. |

## Tecnologias

- Flutter
- Dart
- Material 3
- flutter_local_notifications
- timezone

## Estrutura do projeto

```text
lib/
├── data/
│   └── app_state.dart
├── models/
│   ├── exercise.dart
│   ├── workout.dart
│   └── workout_session.dart
├── services/
│   └── notification_service.dart
├── main.dart
└── workout_execution_screen.dart
```

## Como executar

Pré-requisitos:

- Flutter SDK
- Android Studio ou VS Code
- Dispositivo Android físico ou emulador

Instale as dependências:

```bash
flutter pub get
```

Execute o aplicativo:

```bash
flutter run
```

Para gerar um APK de release:

```bash
flutter build apk --release
```

O arquivo gerado ficará em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Status do projeto

O aplicativo já possui criação e organização de treinos, cadastro de exercícios, execução de treinos, resumo semanal e notificações locais.

A aba de relatórios ainda está em desenvolvimento e deverá evoluir para exibir métricas como carga, volume semanal e progresso por exercício.
