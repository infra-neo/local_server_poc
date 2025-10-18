import React from 'react';
import { Card, CardContent, CardActions, Typography, Button, Chip, Box } from '@mui/material';
import { motion } from 'framer-motion';
import ComputerIcon from '@mui/icons-material/Computer';
import PowerSettingsNewIcon from '@mui/icons-material/PowerSettingsNew';
import PowerOffIcon from '@mui/icons-material/PowerOff';

const WorkspaceCard = ({ workspace }) => {
  const isOnline = workspace.status === 'online';
  
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
      whileHover={{ scale: 1.03, boxShadow: '0 8px 16px rgba(0,0,0,0.2)' }}
    >
      <Card sx={{ 
        minWidth: 275, 
        height: '100%',
        background: isOnline 
          ? 'linear-gradient(135deg, #11998e 0%, #38ef7d 100%)' 
          : 'linear-gradient(135deg, #485563 0%, #29323c 100%)',
        color: 'white'
      }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h5" component="div" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <ComputerIcon />
              {workspace.name}
            </Typography>
            <Chip 
              icon={isOnline ? <PowerSettingsNewIcon /> : <PowerOffIcon />}
              label={isOnline ? 'Online' : 'Offline'} 
              color={isOnline ? 'success' : 'default'}
              size="small"
              sx={{ 
                backgroundColor: isOnline ? 'rgba(76, 175, 80, 0.9)' : 'rgba(158, 158, 158, 0.9)'
              }}
            />
          </Box>
          
          <Typography variant="body2" sx={{ mt: 2, opacity: 0.9 }}>
            Provider: {workspace.node.provider_type.toUpperCase()}
          </Typography>
          
          <Typography variant="body2" sx={{ opacity: 0.9 }}>
            Node: {workspace.node.name}
          </Typography>
          
          {workspace.node.ip_addresses && workspace.node.ip_addresses.length > 0 && (
            <Typography variant="body2" sx={{ opacity: 0.9 }}>
              IP: {workspace.node.ip_addresses[0]}
            </Typography>
          )}
          
          {workspace.node.cpu_count && (
            <Typography variant="caption" sx={{ display: 'block', mt: 1, opacity: 0.8 }}>
              {workspace.node.cpu_count} vCPUs, {Math.round(workspace.node.memory_mb / 1024)} GB RAM
            </Typography>
          )}
        </CardContent>
        
        <CardActions>
          <Button 
            size="medium" 
            variant="contained"
            disabled={!isOnline}
            sx={{ 
              backgroundColor: 'rgba(255, 255, 255, 0.2)',
              '&:hover': {
                backgroundColor: 'rgba(255, 255, 255, 0.3)'
              },
              color: 'white'
            }}
            onClick={() => {
              if (workspace.connection_url) {
                window.open(workspace.connection_url, '_blank');
              } else {
                alert('Connection URL not configured');
              }
            }}
          >
            {isOnline ? 'Connect' : 'Offline'}
          </Button>
        </CardActions>
      </Card>
    </motion.div>
  );
};

export default WorkspaceCard;
