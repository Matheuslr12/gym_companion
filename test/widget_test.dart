import 'package:flutter_test/flutter_test.dart';

import 'package:gym_companion/main.dart';

void main() {
  testWidgets('home exibe seletor, início e resumo semanal', (tester) async {
    await tester.pumpWidget(const GymCompanionApp());

    expect(find.text('SELECIONAR TREINO'), findsOneWidget);
    expect(find.text('INICIAR TREINO'), findsOneWidget);
    expect(find.text('RESUMO DA SEMANA'), findsOneWidget);
    expect(find.text('Nenhum treino disponível'), findsOneWidget);
  });
}
