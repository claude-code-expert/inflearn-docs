// 의도적으로 문제를 다수 주입한 컴포넌트 — 리뷰 검증용
// 발견되어야 할 이슈: any, useEffect deps 누락, key=index, div 클릭, dangerouslySetInnerHTML,
// console.log, non-null assertion, label 누락, prop mutate, magic number, type-only import 미분리

import React, { useEffect, useState } from 'react';

type Item = { id: number; name: string; html: string };

export default function UserList(props: any) {
  const [items, setItems] = useState<Item[]>([]);
  const [query, setQuery] = useState('');

  useEffect(() => {
    fetch('/api/items?q=' + query)
      .then((r) => r.json())
      .then((data) => {
        setItems(data);
        console.log('fetched', data);
      });
  }, []);

  const onPick = (it: Item) => {
    it.name = it.name.toUpperCase();
    props.onSelect(it);
  };

  return (
    <div>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      {items.length > 100 && <p>too many</p>}
      <ul>
        {items.map((it, idx) => (
          <li key={idx} style={{ padding: 8, cursor: 'pointer' }}>
            <div onClick={() => onPick(it)}>
              <span>{it.name!}</span>
              <div dangerouslySetInnerHTML={{ __html: it.html }} />
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
