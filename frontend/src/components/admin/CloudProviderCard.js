import React from 'react';
import { Card, CardContent, CardActions, Typography, Button, Chip, Box } from '@mui/material';
import { motion } from 'framer-motion';
import CloudIcon from '@mui/icons-material/Cloud';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';

const providerLogos = {
  gcp: '🔵 GCP',
  lxd: '📦 LXD',
  aws: '🟠 AWS',
  azure: '🔷 Azure',
  digitalocean: '🌊 DigitalOcean',
  vultr: '⚡ Vultr',
  alibaba: '🟠 Alibaba',
  oracle: '🔴 Oracle',
  huawei: '🔴 Huawei'
};

const CloudProviderCard = ({ connection, onViewNodes }) => {
  const providerName = providerLogos[connection.provider_type] || connection.provider_type;
  
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
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white'
      }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h5" component="div" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CloudIcon />
              {providerName}
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
        <CardActions>
          <Button 
            size="small" 
            onClick={() => onViewNodes(connection.id)}
            sx={{ color: 'white', borderColor: 'white' }}
            variant="outlined"
          >
            View Nodes
          </Button>
        </CardActions>
      </Card>
    </motion.div>
  );
};

export default CloudProviderCard;
