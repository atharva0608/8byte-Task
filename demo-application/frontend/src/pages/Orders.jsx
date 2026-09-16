import { useState, useEffect } from 'react';
import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export default function Orders() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ customer_name: '', product_name: '', quantity: 1, unit_price: '' });

  const loadOrders = () => {
    setLoading(true);
    axios.get(`${API_BASE}/api/v1/orders/`)
      .then(res => setOrders(res.data))
      .catch(err => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadOrders();
  }, []);

  const createOrder = (e) => {
    e.preventDefault();
    axios.post(`${API_BASE}/api/v1/orders/`, {
      ...form,
      unit_price: parseFloat(form.unit_price)
    }).then(() => {
      setForm({ customer_name: '', product_name: '', quantity: 1, unit_price: '' });
      loadOrders();
    }).catch(err => alert("Error creating order: " + err.message));
  };

  const deleteOrder = (id) => {
    if (confirm("Are you sure you want to delete order " + id + "?")) {
      axios.delete(`${API_BASE}/api/v1/orders/${id}`)
        .then(() => loadOrders())
        .catch(err => alert("Error deleting: " + err.message));
    }
  };

  const updateStatus = (id, newStatus) => {
    axios.patch(`${API_BASE}/api/v1/orders/${id}/status`, { status: newStatus })
      .then(() => loadOrders())
      .catch(err => alert("Error updating status (invalid transition?): " + (err.response?.data?.detail || err.message)));
  };

  return (
    <div>
      <div style={{ marginBottom: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px' }}>
        <h3>Create Order</h3>
        <form onSubmit={createOrder} style={{ display: 'flex', gap: '1rem', alignItems: 'end' }}>
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem' }}>Customer</label>
            <input required value={form.customer_name} onChange={e => setForm({...form, customer_name: e.target.value})} style={{ padding: '0.5rem' }} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem' }}>Product</label>
            <input required value={form.product_name} onChange={e => setForm({...form, product_name: e.target.value})} style={{ padding: '0.5rem' }} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem' }}>Qty</label>
            <input required type="number" min="1" value={form.quantity} onChange={e => setForm({...form, quantity: parseInt(e.target.value)})} style={{ padding: '0.5rem', width: '60px' }} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem' }}>Price</label>
            <input required type="number" step="0.01" value={form.unit_price} onChange={e => setForm({...form, unit_price: e.target.value})} style={{ padding: '0.5rem', width: '100px' }} />
          </div>
          <button type="submit" style={{ padding: '0.5rem 1rem', background: '#2563eb', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>Add Order</button>
        </form>
      </div>

      {loading ? <div>Loading...</div> : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
              <th style={{ padding: '0.5rem' }}>ID</th>
              <th>Customer</th>
              <th>Product</th>
              <th>Qty x Price</th>
              <th>Total</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {orders.map(order => (
              <tr key={order.id} style={{ borderBottom: '1px solid #eee' }}>
                <td style={{ padding: '0.5rem' }}>#{order.id}</td>
                <td>{order.customer_name}</td>
                <td>{order.product_name}</td>
                <td>{order.quantity} x ${order.unit_price}</td>
                <td><b>${order.total}</b></td>
                <td>
                  <select 
                    value={order.status}
                    onChange={(e) => updateStatus(order.id, e.target.value)}
                    style={{ padding: '2px', fontSize: '0.8rem' }}
                  >
                    <option value="PLACED">PLACED</option>
                    <option value="PROCESSING">PROCESSING</option>
                    <option value="SHIPPED">SHIPPED</option>
                    <option value="DELIVERED">DELIVERED</option>
                    <option value="CANCELLED">CANCELLED</option>
                  </select>
                </td>
                <td>
                  <button onClick={() => deleteOrder(order.id)} style={{ color: 'red', border: 'none', background: 'none', cursor: 'pointer' }}>Delete</button>
                </td>
              </tr>
            ))}
            {orders.length === 0 && (
              <tr><td colSpan="7" style={{ textAlign: 'center', padding: '1rem' }}>No orders found.</td></tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
