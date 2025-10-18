import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Grid,
  Box,
  AppBar,
  Toolbar,
  CircularProgress,
  Alert,
  Fab,
  Paper
} from '@mui/material';
import {
  Computer as ComputerIcon,
  Refresh as RefreshIcon
} from '@mui/icons-material';
import { motion } from 'framer-motion';
import axios from 'axios';

import RACConnectionCard from '../components/user/RACConnectionCard';

const API_BASE_URL = process.env.REACT_APP_API_URL || '';

const RACDashboard = () => {
  const [connections, setConnections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchConnections();
  }, []);

  const fetchConnections = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await axios.get(`${API_BASE_URL}/api/v1/rac/connections`);
      setConnections(response.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load RAC connections');
      setLoading(false);
      console.error('Error fetching RAC connections:', err);
    }
  };

  const handleConnectionConnect = (connectionId) => {
    console.log('Connecting to:', connectionId);
  };

  return (
    <Box sx={{ flexGrow: 1, minHeight: '100vh', background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)' }}>
      <AppBar position="static" sx={{ background: 'linear-gradient(90deg, #667eea 0%, #764ba2 100%)' }}>
        <Toolbar>
          <ComputerIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Remote Access Control (RAC) - Windows Connections
          </Typography>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4, pb: 4 }}>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <Paper sx={{ p: 3, mb: 4, background: 'rgba(255,255,255,0.9)' }}>
            <Typography variant="h4" gutterBottom sx={{ color: '#667eea', fontWeight: 'bold' }}>
              Remote Desktop Connections
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Click on any connection to access your remote Windows desktop through Guacamole.
            </Typography>
          </Paper>
        </motion.div>

        {error && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.3 }}
          >
            <Alert severity="error" sx={{ mb: 3 }}>
              {error}
            </Alert>
          </motion.div>
        )}

        {loading ? (
          <Box display="flex" justify="center" alignItems="center" minHeight="200px">
            <CircularProgress size={50} />
          </Box>
        ) : (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            {connections.length === 0 ? (
              <Paper sx={{ p: 4, textAlign: 'center', background: 'rgba(255,255,255,0.9)' }}>
                <ComputerIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                <Typography variant="h6" color="text.secondary" gutterBottom>
                  No RAC connections available
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Contact your administrator to set up remote desktop connections.
                </Typography>
              </Paper>
            ) : (
              <Grid container spacing={3}>
                {connections.map((connection, index) => (
                  <Grid item xs={12} sm={6} md={4} key={connection.id}>
                    <motion.div
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.5, delay: index * 0.1 }}
                    >
                      <RACConnectionCard
                        connection={connection}
                        onConnect={handleConnectionConnect}
                      />
                    </motion.div>
                  </Grid>
                ))}
              </Grid>
            )}
          </motion.div>
        )}

        <Fab
          color="primary"
          aria-label="refresh"
          sx={{
            position: 'fixed',
            bottom: 16,
            right: 16,
            background: 'linear-gradient(45deg, #667eea 30%, #764ba2 90%)'
          }}
          onClick={fetchConnections}
        >
          <RefreshIcon />
        </Fab>
      </Container>
    </Box>
  );
};

export default RACDashboard;