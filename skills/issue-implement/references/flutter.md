# Flutter / Dart — Regole di Implementazione

## Test

### Widget test (obbligatori per ogni nuovo widget)
```dart
testWidgets('descrizione comportamento atteso', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // override provider con mock data
        expensesProvider.overrideWith((ref) => mockExpenses),
      ],
      child: const MaterialApp(home: MyWidget()),
    ),
  );
  await tester.pump(); // oppure pumpAndSettle() per animazioni

  expect(find.text('Totale: €120.00'), findsOneWidget);
  expect(find.byType(ListView), findsOneWidget);
});
```

### Test overflow (obbligatorio per ogni schermata)
```dart
testWidgets('no overflow on small screen', (tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(/* widget */);
  await tester.pump();

  expect(tester.takeException(), isNull);
});
```

### Comandi test
```bash
flutter test                        # tutti i test
flutter test test/widget/           # solo widget test
flutter test --coverage             # con coverage
flutter analyze                     # lint e type check
```

---

## Struttura widget

### Stateless vs Stateful
- `StatelessWidget`: preferisci sempre quando possibile
- `StatefulWidget`: solo se hai stato locale che non appartiene al provider
- Con Riverpod: usa `ConsumerWidget` o `ConsumerStatefulWidget`

### Layout senza overflow
```dart
// ❌ Colonna senza scroll in una schermata
Column(children: [...])

// ✅ Schermata con contenuto scrollabile
Scaffold(
  body: SingleChildScrollView(
    child: Column(children: [...]),
  ),
)

// ✅ Lista di elementi
Scaffold(
  body: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => ItemTile(item: items[i]),
  ),
)

// ✅ Layout con parte fissa + parte scrollabile
Scaffold(
  body: Column(
    children: [
      const FixedHeader(),           // altezza fissa
      Expanded(                      // prende lo spazio rimanente
        child: ListView.builder(...),
      ),
    ],
  ),
)
```

### SafeArea e MediaQuery
```dart
// Usa SafeArea per evitare overlap con notch/barra stato
Scaffold(
  body: SafeArea(
    child: ...,
  ),
)

// Non hardcodare dimensioni — usa MediaQuery
final screenHeight = MediaQuery.of(context).size.height;
```

---

## Riverpod

### Provider senza logica nel widget
```dart
// ❌ Logica nel widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
    final filtered = data.where((e) => e.amount > 100).toList(); // ❌
    return ListView(...);
  }
}

// ✅ Logica nel provider
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final all = ref.watch(expensesProvider);
  return all.where((e) => e.amount > 100).toList();
});
```

### AsyncValue — gestisci sempre i 3 stati
```dart
final asyncData = ref.watch(myAsyncProvider);

return asyncData.when(
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => ErrorWidget(err.toString()),
  data: (data) => MyDataWidget(data: data),
);
```

---

## Navigazione (go_router)

```dart
// Naviga
context.go('/expenses');
context.push('/expenses/$id');

// Passa parametri
context.push('/expense/detail', extra: expense);

// Torna indietro
context.pop();
context.pop(result); // con valore di ritorno
```

---

## Supabase (client Flutter)

```dart
// Query base
final response = await supabase
    .from('expenses')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);

// Insert
await supabase.from('expenses').insert({
  'user_id': userId,
  'amount': amount,
  'description': description,
});

// Update
await supabase.from('expenses')
    .update({'amount': newAmount})
    .eq('id', expenseId);

// Delete
await supabase.from('expenses').delete().eq('id', expenseId);

// Gestione errori
try {
  await supabase.from('expenses').insert(data);
} on PostgrestException catch (e) {
  debugPrint('DB error: ${e.message}');
  // mostra feedback utente
}
```

---

## Checklist Flutter pre-commit

- [ ] `flutter analyze` → zero errori/warning
- [ ] `flutter test` → tutti verdi, nessuna regressione
- [ ] Nessun `print()` — solo `debugPrint()`
- [ ] Nessun layout senza scroll su schermate con contenuto variabile
- [ ] `SafeArea` presente nelle schermate principali
- [ ] AsyncValue gestisce loading + error + data
- [ ] Provider senza logica nel widget (usa provider derivati)
