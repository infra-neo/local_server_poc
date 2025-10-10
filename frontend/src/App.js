import React, { useState } from 'react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Box, Tabs, Tab } from '@mui/material';

import AdminDashboard from './pages/AdminDashboard';
import UserDashboard from './pages/UserDashboard';

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

function App() {
  const [currentTab, setCurrentTab] = useState(0);

  const handleTabChange = (event, newValue) => {
    setCurrentTab(newValue);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ width: '100%' }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'background.paper' }}>
          <Tabs value={currentTab} onChange={handleTabChange} centered>
            <Tab label="👤 User View" />
            <Tab label="⚙️ Admin View" />
          </Tabs>
        </Box>
        <Box>
          {currentTab === 0 && <UserDashboard />}
          {currentTab === 1 && <AdminDashboard />}
        </Box>
      </Box>
    </ThemeProvider>
  );
}

export default App;
