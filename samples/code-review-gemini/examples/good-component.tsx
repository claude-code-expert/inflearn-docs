// bad-component.tsx 의 문제들을 모두 수정한 대비용 깨끗한 버전

import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';

const MAX_ITEMS = 100;

type Item = Readonly<{ id: number; name: string; description: string }>;

type Props = Readonly<{
  onSelect: (item: Item) => void;
  renderEmpty?: () => ReactNode;
}>;

export function UserList({ onSelect, renderEmpty }: Props) {
  const [items, setItems] = useState<readonly Item[]>([]);
  const [query, setQuery] = useState('');

  useEffect(() => {
    const ac = new AbortController();
    const url = `/api/items?q=${encodeURIComponent(query)}`;
    fetch(url, { signal: ac.signal })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`))))
      .then((data: Item[]) => setItems(data))
      .catch((err) => {
        if ((err as { name?: string }).name !== 'AbortError') {
          console.warn('fetch items failed', err);
        }
      });
    return () => ac.abort();
  }, [query]);

  const handlePick = (item: Item) => {
    onSelect({ ...item, name: item.name.toUpperCase() });
  };

  if (items.length === 0 && renderEmpty) return <>{renderEmpty()}</>;

  return (
    <section aria-label="user list">
      <label>
        검색
        <input value={query} onChange={(e) => setQuery(e.target.value)} />
      </label>
      {items.length > MAX_ITEMS && <p role="status">결과가 많습니다 — 검색어를 좁히세요.</p>}
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            <button type="button" onClick={() => handlePick(item)}>
              <span>{item.name}</span>
              <span>{item.description}</span>
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
}
