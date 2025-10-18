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
  Button,
  Paper
} from '@mui/material';
import { motion } from 'framer-motion';
import WorkspacesIcon from '@mui/icons-material/Workspaces';
import ComputerIcon from '@mui/icons-material/Computer';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

import WorkspaceCard from '../components/user/WorkspaceCard';

const API_BASE_URL = process.env.REACT_APP_API_URL || '';

const UserDashboard = () => {
  const [workspaces, setWorkspaces] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

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

            <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" gutterBottom>
            My Workspaces
          </Typography>
          <Button
            variant="contained"
            color="secondary"
            startIcon={<ComputerIcon />}
            onClick={() => navigate('/user/rac')}
            sx={{
              background: 'linear-gradient(45deg, #667eea 30%, #764ba2 90%)',
              '&:hover': {
                background: 'linear-gradient(45deg, #5a67d8 30%, #6b46c1 90%)'
              }
            }}
          >
            Remote Desktop (RAC)
          </Button>
        </Box>

        {/* Quick Access Card for RAC */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <Paper 
            sx={{ 
              p: 3, 
              mb: 4, 
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              cursor: 'pointer'
            }}
            onClick={() => navigate('/user/rac')}
          >
            <Box display="flex" alignItems="center">
              <ComputerIcon sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h6" gutterBottom>
                  Quick Access: Windows Remote Desktop
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.9 }}>
                  Connect directly to your Windows desktop (100.95.223.18) through Guacamole
                </Typography>
              </Box>
            </Box>
          </Paper>
        </motion.div>

        <Typography variant="body1" color="textSecondary" paragraph>
          Access your virtual machines and containers
        </Typography>

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
