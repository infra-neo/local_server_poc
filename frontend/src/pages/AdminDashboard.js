import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Button,
  Grid,
  Box,
  AppBar,
  Toolbar,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  List,
  ListItem,
  ListItemText,
  CircularProgress,
  Alert,
  ListItemButton,
  Menu,
  MenuItem
} from '@mui/material';
import { motion } from 'framer-motion';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import CloudQueueIcon from '@mui/icons-material/CloudQueue';
import PeopleIcon from '@mui/icons-material/People';
import DesktopWindowsIcon from '@mui/icons-material/DesktopWindows';
import AddBoxIcon from '@mui/icons-material/AddBox';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

import CloudProviderCard from '../components/admin/CloudProviderCard';
import WizardConector from '../components/admin/WizardConector';
import VMCreationWizard from '../components/admin/VMCreationWizard';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

const AdminDashboard = () => {
  const [connections, setConnections] = useState([]);
  const [wizardOpen, setWizardOpen] = useState(false);
  const [vmWizardOpen, setVmWizardOpen] = useState(false);
  const [selectedConnectionForVM, setSelectedConnectionForVM] = useState(null);
  const [nodesDialogOpen, setNodesDialogOpen] = useState(false);
  const [selectedConnection, setSelectedConnection] = useState(null);
  const [nodes, setNodes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [nodeMenuAnchor, setNodeMenuAnchor] = useState(null);
  const [selectedNode, setSelectedNode] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchConnections();
  }, []);

  const fetchConnections = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await axios.get(`${API_BASE_URL}/api/v1/admin/cloud_connections`);
      setConnections(response.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load cloud connections');
      setLoading(false);
    }
  };

  const handleViewNodes = async (connectionId) => {
    setSelectedConnection(connectionId);
    setNodesDialogOpen(true);
    try {
      const response = await axios.get(`${API_BASE_URL}/api/v1/admin/cloud_connections/${connectionId}/nodes`);
      setNodes(response.data);
    } catch (err) {
      setError('Failed to load nodes');
      setNodes([]);
    }
  };

  const handleWizardSuccess = (newConnection) => {
    setConnections([...connections, newConnection]);
  };

  const handleOpenVMWizard = (connectionId) => {
    setSelectedConnectionForVM(connectionId);
    setVmWizardOpen(true);
    setNodesDialogOpen(false);
  };

  const handleVMCreated = () => {
    // Refresh nodes if dialog is open
    if (selectedConnection) {
      handleViewNodes(selectedConnection);
    }
  };

  const handleNodeAction = async (action, nodeId) => {
    setError('');
    try {
      await axios.post(
        `${API_BASE_URL}/api/v1/admin/cloud_connections/${selectedConnection}/nodes/${nodeId}/${action}`
      );
      // Refresh nodes
      handleViewNodes(selectedConnection);
      setNodeMenuAnchor(null);
    } catch (err) {
      setError(`Failed to ${action} node`);
    }
  };

  const handleNodeMenuOpen = (event, node) => {
    setNodeMenuAnchor(event.currentTarget);
    setSelectedNode(node);
  };

  const handleNodeMenuClose = () => {
    setNodeMenuAnchor(null);
    setSelectedNode(null);
  };

  return (
    <DndProvider backend={HTML5Backend}>
      <Box sx={{ flexGrow: 1 }}>
        <AppBar position="static" sx={{ background: 'linear-gradient(90deg, #667eea 0%, #764ba2 100%)' }}>
          <Toolbar>
            <CloudQueueIcon sx={{ mr: 2 }} />
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              Kolaboree NG - Admin Dashboard
            </Typography>
            <Button 
              color="inherit" 
              startIcon={<PeopleIcon />}
              onClick={() => navigate('/admin/users')}
              variant="outlined"
              sx={{ borderColor: 'white', mr: 1 }}
            >
              Users
            </Button>
            <Button 
              color="inherit" 
              startIcon={<DesktopWindowsIcon />}
              onClick={() => navigate('/admin/remote-connections')}
              variant="outlined"
              sx={{ borderColor: 'white', mr: 1 }}
            >
              Remote Access
            </Button>
            <Button 
              color="inherit" 
              startIcon={<AddCircleIcon />}
              onClick={() => setWizardOpen(true)}
              variant="outlined"
              sx={{ borderColor: 'white' }}
            >
              Add Cloud Connection
            </Button>
          </Toolbar>
        </AppBar>

        <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <Typography variant="h4" gutterBottom>
              Cloud Connections
            </Typography>
            <Typography variant="body1" color="textSecondary" paragraph>
              Manage your multi-cloud infrastructure from a single dashboard
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
          ) : connections.length === 0 ? (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.2 }}
            >
              <Alert severity="info">
                No cloud connections configured. Click "Add Cloud Connection" to get started.
              </Alert>
            </motion.div>
          ) : (
            <Grid container spacing={3} sx={{ mt: 2 }}>
              {connections.map((connection, index) => (
                <Grid item xs={12} sm={6} md={4} key={connection.id}>
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                  >
                    <CloudProviderCard 
                      connection={connection} 
                      onViewNodes={handleViewNodes}
                    />
                  </motion.div>
                </Grid>
              ))}
            </Grid>
          )}

          <Box sx={{ mt: 4, p: 3, bgcolor: 'background.paper', borderRadius: 2 }}>
            <Typography variant="h6" gutterBottom>
              💡 Drag & Drop Feature (UI Ready)
            </Typography>
            <Typography variant="body2" color="textSecondary">
              The drag-and-drop functionality is prepared using React DnD. 
              You can extend this to drag users to machines for permission assignment.
            </Typography>
          </Box>
        </Container>

        <WizardConector 
          open={wizardOpen}
          onClose={() => setWizardOpen(false)}
          onSuccess={handleWizardSuccess}
        />

        <Dialog 
          open={nodesDialogOpen} 
          onClose={() => setNodesDialogOpen(false)}
          maxWidth="md"
          fullWidth
        >
          <DialogTitle>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              Nodes / Instances
              <Button 
                startIcon={<AddBoxIcon />}
                variant="contained"
                size="small"
                onClick={() => handleOpenVMWizard(selectedConnection)}
              >
                Create VM
              </Button>
            </Box>
          </DialogTitle>
          <DialogContent>
            {nodes.length === 0 ? (
              <Alert severity="info">No nodes found for this connection</Alert>
            ) : (
              <List>
                {nodes.map((node) => (
                  <ListItemButton key={node.id}>
                    <ListItemText
                      primary={node.name}
                      secondary={`State: ${node.state} | IPs: ${node.ip_addresses.join(', ') || 'N/A'}`}
                    />
                    <IconButton 
                      edge="end" 
                      onClick={(e) => handleNodeMenuOpen(e, node)}
                    >
                      <MoreVertIcon />
                    </IconButton>
                  </ListItemButton>
                ))}
              </List>
            )}
          </DialogContent>
        </Dialog>

        {/* Node Actions Menu */}
        <Menu
          anchorEl={nodeMenuAnchor}
          open={Boolean(nodeMenuAnchor)}
          onClose={handleNodeMenuClose}
        >
          <MenuItem onClick={() => handleNodeAction('start', selectedNode?.id)}>
            Start
          </MenuItem>
          <MenuItem onClick={() => handleNodeAction('stop', selectedNode?.id)}>
            Stop
          </MenuItem>
          <MenuItem onClick={() => handleNodeAction('restart', selectedNode?.id)}>
            Restart
          </MenuItem>
        </Menu>

        <VMCreationWizard
          open={vmWizardOpen}
          onClose={() => setVmWizardOpen(false)}
          connectionId={selectedConnectionForVM}
          onSuccess={handleVMCreated}
        />
      </Box>
    </DndProvider>
  );
};

export default AdminDashboard;
