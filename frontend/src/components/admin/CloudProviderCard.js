import React from 'react';
import { Card, CardContent, CardActions, Typography, Button, Chip, Box, IconButton, Tooltip } from '@mui/material';
import { motion } from 'framer-motion';
import CloudIcon from '@mui/icons-material/Cloud';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PowerSettingsNewIcon from '@mui/icons-material/PowerSettingsNew';
import RestartAltIcon from '@mui/icons-material/RestartAlt';

// Provider logos - using emojis and Material-UI icons
const providerLogos = {
  gcp: { icon: '☁️', color: '#4285F4', label: 'GCP' },
  lxd: { icon: '📦', color: '#E95420', label: 'LXD' },
  aws: { icon: '🟠', color: '#FF9900', label: 'AWS' },
  azure: { icon: '🔷', color: '#0089D6', label: 'Azure' },
  digitalocean: { icon: '🌊', color: '#0080FF', label: 'DigitalOcean' },
  vultr: { icon: '⚡', color: '#007BFC', label: 'Vultr' },
  alibaba: { icon: '🟠', color: '#FF6A00', label: 'Alibaba Cloud' },
  oracle: { icon: '🔴', color: '#F80000', label: 'Oracle Cloud' },
  huawei: { icon: '🔴', color: '#FF0000', label: 'Huawei Cloud' }
};

const CloudProviderCard = ({ connection, onViewNodes }) => {
  const provider = providerLogos[connection.provider_type] || { 
    icon: '☁️', 
    color: '#667eea', 
    label: connection.provider_type 
  };
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      whileHover={{ scale: 1.02 }}
    >
      <Card sx={{ 
        minWidth: 275, 
        height: '100%',
        background: `linear-gradient(135deg, ${provider.color} 0%, ${provider.color}DD 100%)`,
        color: 'white'
      }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h5" component="div" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <span style={{ fontSize: '1.5em' }}>{provider.icon}</span>
              {provider.label}
            </Typography>
            {connection.status === 'connected' && (
              <Chip 
                icon={<CheckCircleIcon />} 
                label="Connected" 
                color="success" 
                size="small"
                sx={{ backgroundColor: 'rgba(76, 175, 80, 0.9)' }}
              />
            )}
          </Box>
          <Typography variant="body2" sx={{ mt: 2, opacity: 0.9 }}>
            Name: {connection.name}
          </Typography>
          {connection.region && (
            <Typography variant="body2" sx={{ opacity: 0.9 }}>
              Region: {connection.region}
            </Typography>
          )}
          <Typography variant="caption" sx={{ mt: 1, display: 'block', opacity: 0.7 }}>
            Connected: {new Date(connection.created_at).toLocaleDateString()}
          </Typography>
        </CardContent>
        <CardActions sx={{ justifyContent: 'space-between', px: 2 }}>
          <Button 
            size="small" 
            onClick={() => onViewNodes(connection.id)}
            sx={{ color: 'white', borderColor: 'white' }}
            variant="outlined"
          >
            View Nodes
          </Button>
          <Box>
            <Tooltip title="Power Management">
              <IconButton size="small" sx={{ color: 'white' }}>
                <PowerSettingsNewIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Restart">
              <IconButton size="small" sx={{ color: 'white' }}>
                <RestartAltIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </CardActions>
      </Card>
    </motion.div>
  );
};

export default CloudProviderCard;
