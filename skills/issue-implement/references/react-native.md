# React Native / Expo — Regole di Implementazione

## Test

### Jest + React Native Testing Library
```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

test('mostra lista tornei quando i dati arrivano', () => {
  render(<TournamentList tournaments={mockTournaments} />);
  expect(screen.getByText('Torneo Roma 2026')).toBeTruthy();
});

test('mostra stato vuoto quando lista è empty', () => {
  render(<TournamentList tournaments={[]} />);
  expect(screen.getByText('Nessun torneo')).toBeTruthy();
});
```

### Comandi test
```bash
npm test                  # tutti i test
npm test -- --watch       # watch mode
npm test -- --coverage    # con coverage
```

---

## Struttura componenti

### Componente funzionale standard
```tsx
interface Props {
  tournamentId: string;
  onPress: (id: string) => void;
}

export const TournamentCard: React.FC<Props> = ({ tournamentId, onPress }) => {
  return (
    <TouchableOpacity onPress={() => onPress(tournamentId)}>
      <Text>{tournamentId}</Text>
    </TouchableOpacity>
  );
};
```

### ScrollView obbligatorio per contenuto variabile
```tsx
// ❌ View fissa con contenuto lungo
<View>
  {items.map(item => <ItemCard key={item.id} item={item} />)}
</View>

// ✅ FlatList per liste
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemCard item={item} />}
  ListEmptyComponent={<EmptyState />}
/>

// ✅ ScrollView per contenuto misto
<ScrollView>
  <Header />
  <Content />
</ScrollView>
```

---

## Gestione stato async

### Loading / Error / Data — sempre tutti e tre
```tsx
const [data, setData] = useState<Tournament[]>([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string | null>(null);

useEffect(() => {
  fetchTournaments()
    .then(setData)
    .catch((e) => setError(e.message))
    .finally(() => setLoading(false));
}, []);

if (loading) return <ActivityIndicator />;
if (error) return <ErrorView message={error} />;
return <TournamentList data={data} />;
```

---

## Cache e stato stale — regole fondamentali

Gli errori più comuni nel progetto BeachRef vengono da stato stale. Regole:

```tsx
// ✅ Chiave cache sempre year-scoped
const cacheKey = `matches_${tournamentId}_${year}`;

// ✅ Guard su array vuoto — non fare fallback su dati stale
const matches = await fetchMatches(tournamentId, year);
if (!matches || matches.length === 0) {
  return []; // lista vuota, MAI fallback su cache precedente
}

// ✅ Reset stato quando cambia il torneo
useEffect(() => {
  setMatches([]);       // reset esplicito
  setLoading(true);
  fetchMatches(id).then(setMatches).finally(() => setLoading(false));
}, [id]); // dipendenza su id
```

---

## Navigazione (React Navigation)

```tsx
// Naviga
navigation.navigate('TournamentDetail', { id: tournament.id });
navigation.goBack();

// Tipizzazione
type RootStackParamList = {
  TournamentList: undefined;
  TournamentDetail: { id: string };
};
```

---

## Supabase (client JS)

```ts
// Query
const { data, error } = await supabase
  .from('tournaments')
  .select('*')
  .eq('year', 2026)
  .order('start_date', { ascending: true });

if (error) throw error;

// Insert
const { error } = await supabase.from('matches').insert({ tournament_id, score });
if (error) throw error;
```

---

## Checklist React Native pre-commit

- [ ] `npm test` → tutti verdi, nessuna regressione
- [ ] Nessun `console.log()` lasciato
- [ ] FlatList / ScrollView per ogni lista o contenuto variabile
- [ ] Loading + error + data gestiti ovunque
- [ ] Cache keys year-scoped (se presente caching)
- [ ] Reset stato esplicito al cambio di ID/parametro
- [ ] Props tipizzate con TypeScript interface
