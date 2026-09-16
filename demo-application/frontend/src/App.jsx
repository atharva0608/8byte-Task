import { Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, ShoppingCart } from 'lucide-react';
import Dashboard from './pages/Dashboard';
import Orders from './pages/Orders';

function App() {
  const location = useLocation();

  const getNavClass = (path) => {
    return location.pathname === path 
      ? 'flex items-center gap-2 p-2 rounded bg-blue-100 text-blue-700' 
      : 'flex items-center gap-2 p-2 rounded text-gray-700 hover:bg-gray-100';
  };

  return (
    <div style={{ display: 'flex', height: '100vh', fontFamily: 'sans-serif' }}>
      {/* Sidebar */}
      <div style={{ width: '250px', borderRight: '1px solid #ddd', padding: '1rem', backgroundColor: '#f9f9f9' }}>
        <h2 style={{ marginBottom: '2rem', color: '#333' }}>OMS Ops</h2>
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <Link to="/" className={getNavClass('/')} style={{ textDecoration: 'none', color: '#333' }}>
            <LayoutDashboard size={18} /> Dashboard
          </Link>
          <Link to="/orders" className={getNavClass('/orders')} style={{ textDecoration: 'none', color: '#333' }}>
            <ShoppingCart size={18} /> Orders
          </Link>
        </nav>
      </div>

      {/* Main Content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <header style={{ padding: '1rem 2rem', borderBottom: '1px solid #ddd', display: 'flex', alignItems: 'center' }}>
          <h1 style={{ margin: 0, fontSize: '1.25rem', color: '#555' }}>
            {location.pathname === '/' ? 'Dashboard' : 'Order Management'}
          </h1>
        </header>
        <main style={{ padding: '2rem', flex: 1, overflowY: 'auto', backgroundColor: '#fff' }}>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/orders" element={<Orders />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

export default App;
