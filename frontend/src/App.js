import React, { useState } from 'react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Box, Tabs, Tab } from '@mui/material';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';

import AdminDashboard from './pages/AdminDashboard';
import UserDashboard from './pages/UserDashboard';
import UsersManagement from './pages/UsersManagement';
import RemoteConnectionView from './pages/RemoteConnectionView';
import RACDashboard from './pages/RACDashboard';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#667eea',
    },
    secondary: {
      main: '#764ba2',
    },
  },
  typography: {
    fontFamily: [
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
  },
});

function TabNavigation() {
  const location = useLocation();
  const navigate = useNavigate();
  
  // Determine current tab based on route
  const getCurrentTab = () => {
    if (location.pathname.startsWith('/admin')) return 1;
    return 0;
  };

  const handleTabChange = (event, newValue) => {
    if (newValue === 0) {
      navigate('/user');
    } else {
      navigate('/admin');
    }
  };

  // Hide tabs on specific admin pages
  const shouldShowTabs = !location.pathname.includes('/users') && !location.pathname.includes('/remote-connections');

  return shouldShowTabs ? (
    <Box sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'background.paper' }}>
      <Tabs value={getCurrentTab()} onChange={handleTabChange} centered>
        <Tab label="👤 User View" />
        <Tab label="⚙️ Admin View" />
      </Tabs>
    </Box>
  ) : null;
}

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Box sx={{ width: '100%' }}>
          <TabNavigation />
          <Box>
            <Routes>
              <Route path="/" element={<Navigate to="/user" replace />} />
              <Route path="/user" element={<UserDashboard />} />
              <Route path="/user/rac" element={<RACDashboard />} />
              <Route path="/admin" element={<AdminDashboard />} />
              <Route path="/admin/users" element={<UsersManagement />} />
              <Route path="/admin/remote-connections" element={<RemoteConnectionView />} />
              <Route path="/admin/remote-connections/:connectionId" element={<RemoteConnectionView />} />
            </Routes>
          </Box>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;
