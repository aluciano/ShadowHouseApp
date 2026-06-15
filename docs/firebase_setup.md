# Configuração Firebase

Este projeto ainda usa os repositórios fake por padrão. A troca para Firestore
deve acontecer em `lib/repositories/repository_registry.dart`, substituindo as
implementações fake por implementações Firebase.

## Pacotes Flutter

Quando o acesso ao `pub.dev` estiver funcionando no ambiente, adicione:

```sh
flutter pub add firebase_core cloud_firestore
```

Depois rode:

```sh
flutter pub get
```

## FlutterFire

Com um projeto Firebase criado, instale/configure o FlutterFire CLI e rode:

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

O comando deve gerar `lib/firebase_options.dart` e registrar os apps de cada
plataforma selecionada.

## Android

Para Android, confirme que o app Firebase usa:

```text
com.aluciano.shadow_house
```

O FlutterFire CLI normalmente ajusta os arquivos Gradle necessários. Caso a
configuração manual seja necessária, adicione o plugin do Google Services no
Gradle do Android e garanta que `android/app/google-services.json` corresponda
ao projeto Firebase correto.

## Firestore

Ative o Cloud Firestore no console Firebase. A primeira versão online deve
criar coleções para:

- `rooms`: dados públicos da sala, status, jogadores e turno atual.
- `matches`: partidas finalizadas para o histórico.
- `playerHands`: mãos privadas por jogador.

As regras de segurança precisam impedir que um jogador leia a mão de outro.
