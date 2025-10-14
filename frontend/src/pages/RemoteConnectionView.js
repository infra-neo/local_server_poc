import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Box,
  AppBar,
  Toolbar,
  Paper,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  IconButton,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Chip
} from '@mui/material';
import { motion } from 'framer-motion';
import DesktopWindowsIcon from '@mui/icons-material/DesktopWindows';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import ConnectWithoutContactIcon from '@mui/icons-material/ConnectWithoutContact';
import { useNavigate, useParams } from 'react-router-dom';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

const RemoteConnectionView = () => {
  const [nodes, setNodes] = useState([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedNode, setSelectedNode] = useState(null);
  const [protocol, setProtocol] = useState('rdp');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [connectionUrl, setConnectionUrl] = useState('');
  const navigate = useNavigate();
  const { connectionId } = useParams();

  useEffect(() => {
    if (connectionId) {
      fetchNodes();
    }
  }, [connectionId]);

  const fetchNodes = async () => {
    try {
      const response = await axios.get(
        `${API_BASE_URL}/api/v1/admin/cloud_connections/${connectionId}/nodes`
      );
      setNodes(response.data);
    } catch (err) {
      setError('Failed to load nodes');
    }
  };

  const handleConnect = (node) => {
    setSelectedNode(node);
    setDialogOpen(true);
  };

  const handleCreateConnection = async () => {
    setError('');
    try {
      const response = await axios.post(
        `${API_BASE_URL}/api/v1/admin/guacamole/connect`,
        {
          node_id: selectedNode.id,
          protocol,
          username,
          password
        }
      );

      // Open Guacamole in new window/iframe
      const guacUrl = `http://localhost:8080${response.data.guacamole_url}`;
      setConnectionUrl(guacUrl);
      
      // Open in new window
      window.open(guacUrl, '_blank', 'width=1280,height=720');
      
      setDialogOpen(false);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create connection');
    }
  };

  const protocolInfo = {
    rdp: { icon: '🖥️', label: 'RDP (Remote Desktop)', port: 3389 },
    vnc: { icon: '🖼️', label: 'VNC (Virtual Network Computing)', port: 5900 },
    ssh: { icon: '💻', label: 'SSH (Secure Shell)', port: 22 }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static" sx={{ background: 'linear-gradient(90deg, #667eea 0%, #764ba2 100%)' }}>
        <Toolbar>
          <IconButton
            edge="start"
            color="inherit"
            onClick={() => navigate('/admin')}
            sx={{ mr: 2 }}
          >
            <ArrowBackIcon />
          </IconButton>
          <DesktopWindowsIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Remote Desktop Connections (Guacamole)
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
            Available Machines
          </Typography>
          <Typography variant="body1" color="textSecondary" paragraph>
            Connect to remote machines using HTML5-based Guacamole (RDP, VNC, SSH)
          </Typography>
        </motion.div>

        <Box sx={{ mt: 3, p: 2, bgcolor: 'info.light', borderRadius: 2 }}>
          <Typography variant="body2">
            🌐 <strong>Apache Guacamole Integration:</strong> Connect to your VMs and containers 
            directly from your browser using HTML5 and WebRTC. No client software required!
          </Typography>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {error}
          </Alert>
        )}

        <Grid container spacing={3} sx={{ mt: 2 }}>
          {nodes.map((node, index) => (
            <Grid item xs={12} sm={6} md={4} key={node.id}>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
              >
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      {node.name}
                    </Typography>
                    <Chip 
                      label={node.state} 
                      color={node.state === 'running' ? 'success' : 'default'}
                      size="small"
                      sx={{ mb: 1 }}
                    />
                    <Typography variant="body2" color="textSecondary">
                      Provider: {node.provider_type}
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      IPs: {node.ip_addresses.join(', ') || 'N/A'}
                    </Typography>
                  </CardContent>
                  <CardActions>
                    <Button 
                      size="small" 
                      variant="contained"
                      startIcon={<ConnectWithoutContactIcon />}
                      onClick={() => handleConnect(node)}
                      disabled={node.state !== 'running'}
                    >
                      Connect
                    </Button>
                  </CardActions>
                </Card>
              </motion.div>
            </Grid>
          ))}
        </Grid>

        {nodes.length === 0 && (
          <Alert severity="info" sx={{ mt: 3 }}>
            No nodes available. Please add a cloud connection and provision some VMs first.
          </Alert>
        )}
      </Container>

      {/* Connection Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          Connect to {selectedNode?.name}
        </DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <FormControl fullWidth margin="normal">
            <InputLabel>Connection Protocol</InputLabel>
            <Select
              value={protocol}
              onChange={(e) => setProtocol(e.target.value)}
              label="Connection Protocol"
            >
              {Object.entries(protocolInfo).map(([key, info]) => (
                <MenuItem key={key} value={key}>
                  {info.icon} {info.label} (Port {info.port})
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <TextField
            fullWidth
            label="Username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            margin="normal"
          />

          <TextField
            fullWidth
            label="Password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            margin="normal"
          />

          <Alert severity="info" sx={{ mt: 2 }}>
            Connection will open in a new window using Apache Guacamole HTML5 client
          </Alert>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreateConnection} variant="contained">
            Connect
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RemoteConnectionView;
