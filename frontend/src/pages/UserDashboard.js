import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Grid,
  Box,
  AppBar,
  Toolbar,
  CircularProgress,
  Alert
} from '@mui/material';
import { motion } from 'framer-motion';
import WorkspacesIcon from '@mui/icons-material/Workspaces';
import axios from 'axios';

import WorkspaceCard from '../components/user/WorkspaceCard';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

const UserDashboard = () => {
  const [workspaces, setWorkspaces] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchWorkspaces();
  }, []);

  const fetchWorkspaces = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await axios.get(`${API_BASE_URL}/api/v1/user/my_workspaces`);
      setWorkspaces(response.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load workspaces');
      setLoading(false);
    }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static" sx={{ background: 'linear-gradient(90deg, #11998e 0%, #38ef7d 100%)' }}>
        <Toolbar>
          <WorkspacesIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Kolaboree NG - My Workspaces
          </Typography>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <Typography variant="h4" gutterBottom>
            My Workspaces
          </Typography>
          <Typography variant="body1" color="textSecondary" paragraph>
            Access your virtual machines and containers
          </Typography>
        </motion.div>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
            <CircularProgress />
          </Box>
        ) : workspaces.length === 0 ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.2 }}
          >
            <Alert severity="info">
              No workspaces assigned to you yet. Contact your administrator.
            </Alert>
          </motion.div>
        ) : (
          <Grid container spacing={3} sx={{ mt: 2 }}>
            {workspaces.map((workspace, index) => (
              <Grid item xs={12} sm={6} md={4} key={workspace.id}>
                <motion.div
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <WorkspaceCard workspace={workspace} />
                </motion.div>
              </Grid>
            ))}
          </Grid>
        )}
      </Container>
    </Box>
  );
};

export default UserDashboard;
