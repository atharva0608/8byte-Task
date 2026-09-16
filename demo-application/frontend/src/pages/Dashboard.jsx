import { useState, useEffect } from 'react';
import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    axios.get(`${API_BASE}/api/v1/dashboard/`)
      .then(res => {
        setStats(res.data);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading dashboard...</div>;
  if (!stats) return <div>Error loading stats</div>;

  return (
    <div>
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', flexWrap: 'wrap' }}>
        <div style={{ padding: '1.5rem', border: '1px solid #ddd', borderRadius: '8px', minWidth: '150px' }}>
          <h3 style={{ margin: '0 0 0.5rem 0', color: '#666' }}>Total Orders</h3>
          <div style={{ fontSize: '2rem', fontWeight: 'bold' }}>{stats.total}</div>
        </div>
        {Object.entries(stats.by_status).map(([status, count]) => (
          <div key={status} style={{ padding: '1.5rem', border: '1px solid #ddd', borderRadius: '8px', minWidth: '150px' }}>
            <h3 style={{ margin: '0 0 0.5rem 0', color: '#666', fontSize: '0.9rem' }}>{status}</h3>
            <div style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>{count}</div>
          </div>
        ))}
      </div>

      <h3>Recent Activity</h3>
      <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '1rem' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
            <th style={{ padding: '0.5rem' }}>ID</th>
            <th>Customer</th>
            <th>Product</th>
            <th>Status</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          {stats.recent_orders.map(order => (
            <tr key={order.id} style={{ borderBottom: '1px solid #eee' }}>
              <td style={{ padding: '0.5rem' }}>#{order.id}</td>
              <td>{order.customer_name}</td>
              <td>{order.product_name}</td>
              <td><span style={{ fontSize: '0.8rem', padding: '2px 6px', background: '#eef', borderRadius: '4px' }}>{order.status}</span></td>
              <td>${order.total}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
