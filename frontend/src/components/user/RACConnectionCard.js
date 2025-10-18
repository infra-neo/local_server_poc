import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Button,
  Box,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Alert,
  CircularProgress
} from '@mui/material';
import {
  Computer as ComputerIcon,
  PlayArrow as ConnectIcon,
  Info as InfoIcon,
  CheckCircle as CheckIcon
} from '@mui/icons-material';
import { motion } from 'framer-motion';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || '';

const RACConnectionCard = ({ connection, onConnect }) => {
  const [connecting, setConnecting] = useState(false);
  const [showInstructions, setShowInstructions] = useState(false);
  const [connectionDetails, setConnectionDetails] = useState(null);

  const handleConnect = async () => {
    setConnecting(true);
    try {
      const response = await axios.post(`${API_BASE_URL}/api/v1/rac/connections/${connection.id}/connect`);
      setConnectionDetails(response.data);
      setShowInstructions(true);
      
      // Open connection in new tab after showing instructions
      setTimeout(() => {
        window.open(response.data.connection_url, '_blank');
        setConnecting(false);
        setShowInstructions(false);
      }, 3000);
      
    } catch (error) {
      console.error('Failed to connect:', error);
      setConnecting(false);
    }
  };

  const getProtocolColor = (protocol) => {
    switch (protocol.toLowerCase()) {
      case 'rdp': return 'primary';
      case 'vnc': return 'secondary';
      case 'ssh': return 'success';
      default: return 'default';
    }
  };

  return (
    <>
      <motion.div
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        transition={{ duration: 0.2 }}
      >
        <Card 
          sx={{ 
            height: '100%', 
            display: 'flex', 
            flexDirection: 'column',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            '&:hover': {
              boxShadow: '0 8px 25px rgba(0,0,0,0.15)'
            }
          }}
        >
          <CardContent sx={{ flexGrow: 1 }}>
            <Box display="flex" alignItems="center" mb={2}>
              <ComputerIcon sx={{ mr: 1, fontSize: 30 }} />
              <Typography variant="h6" component="h3">
                {connection.name}
              </Typography>
            </Box>
            
            <Typography variant="body2" sx={{ mb: 2, opacity: 0.9 }}>
              {connection.description}
            </Typography>
            
            <Box display="flex" gap={1} mb={2}>
              <Chip 
                label={connection.protocol.toUpperCase()} 
                color={getProtocolColor(connection.protocol)}
                size="small"
              />
              <Chip 
                label={connection.status} 
                color="success"
                size="small"
              />
              {connection.requires_permission && (
                <Chip 
                  icon={<InfoIcon />}
                  label="Requires Approval" 
                  color="warning"
                  size="small"
                />
              )}
            </Box>
          </CardContent>
          
          <CardActions>
            <Button
              variant="contained"
              color="success"
              startIcon={connecting ? <CircularProgress size={16} /> : <ConnectIcon />}
              onClick={handleConnect}
              disabled={connecting}
              fullWidth
              sx={{
                background: 'rgba(255,255,255,0.2)',
                '&:hover': {
                  background: 'rgba(255,255,255,0.3)'
                }
              }}
            >
              {connecting ? 'Connecting...' : 'Connect'}
            </Button>
          </CardActions>
        </Card>
      </motion.div>

      {/* Instructions Dialog */}
      <Dialog open={showInstructions} onClose={() => setShowInstructions(false)} maxWidth="md">
        <DialogTitle>
          <Box display="flex" alignItems="center">
            <InfoIcon sx={{ mr: 1 }} />
            Remote Desktop Connection Starting
          </Box>
        </DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mb: 2 }}>
            Your remote desktop connection is starting. Please follow these steps:
          </Alert>
          
          {connectionDetails?.instructions && (
            <List>
              {connectionDetails.instructions.steps.map((step, index) => (
                <ListItem key={index}>
                  <ListItemIcon>
                    <CheckIcon color="success" />
                  </ListItemIcon>
                  <ListItemText primary={step} />
                </ListItem>
              ))}
            </List>
          )}
          
          <Alert severity="warning" sx={{ mt: 2 }}>
            <strong>Important:</strong> When you connect to the Windows machine, you may be 
            disconnected from your local session. This is normal behavior for RDP connections.
          </Alert>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowInstructions(false)}>
            I Understand
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default RACConnectionCard;