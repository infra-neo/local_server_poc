import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Stepper,
  Step,
  StepLabel,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Box,
  Typography,
  Alert
} from '@mui/material';
import { motion, AnimatePresence } from 'framer-motion';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

const steps = ['Select Provider', 'Configure Credentials', 'Connect'];

const providerOptions = [
  { value: 'gcp', label: '🔵 Google Cloud Platform (GCP)', functional: true },
  { value: 'lxd', label: '📦 LXD/MicroCloud', functional: true },
  { value: 'aws', label: '🟠 AWS EC2', functional: false },
  { value: 'azure', label: '🔷 Microsoft Azure', functional: false },
  { value: 'digitalocean', label: '🌊 DigitalOcean', functional: false },
  { value: 'vultr', label: '⚡ Vultr', functional: false },
  { value: 'alibaba', label: '🟠 Alibaba Cloud', functional: false },
  { value: 'oracle', label: '🔴 Oracle Cloud', functional: false },
  { value: 'huawei', label: '🔴 Huawei Cloud', functional: false },
];

const WizardConector = ({ open, onClose, onSuccess }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [provider, setProvider] = useState('');
  const [name, setName] = useState('');
  const [credentials, setCredentials] = useState({});
  const [region, setRegion] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleNext = () => {
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleReset = () => {
    setActiveStep(0);
    setProvider('');
    setName('');
    setCredentials({});
    setRegion('');
    setError('');
  };

  const handleConnect = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await axios.post(`${API_BASE_URL}/api/v1/admin/cloud_connections`, {
        name,
        provider_type: provider,
        credentials,
        region: region || null
      });
      
      setLoading(false);
      onSuccess(response.data);
      handleReset();
      onClose();
    } catch (err) {
      setLoading(false);
      setError(err.response?.data?.detail || 'Failed to connect. Please check your credentials.');
    }
  };

  const renderProviderForm = () => {
    switch (provider) {
      case 'gcp':
        return (
          <Box>
            <TextField
              fullWidth
              label="Connection Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              margin="normal"
              required
            />
            <TextField
              fullWidth
              label="Region (e.g., us-central1-a)"
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              margin="normal"
              placeholder="us-central1-a"
            />
            <TextField
              fullWidth
              multiline
              rows={6}
              label="Service Account JSON"
              value={credentials.service_account_json || ''}
              onChange={(e) => setCredentials({ ...credentials, service_account_json: e.target.value })}
              margin="normal"
              required
              placeholder='{"type": "service_account", "project_id": "...", ...}'
            />
            <Typography variant="caption" color="textSecondary">
              Paste your GCP service account JSON credentials here
            </Typography>
          </Box>
        );
      
      case 'lxd':
        return (
          <Box>
            <TextField
              fullWidth
              label="Connection Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              margin="normal"
              required
            />
            <TextField
              fullWidth
              label="LXD Endpoint"
              value={credentials.endpoint || ''}
              onChange={(e) => setCredentials({ ...credentials, endpoint: e.target.value })}
              margin="normal"
              placeholder="https://localhost:8443"
            />
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Client Certificate (Optional)"
              value={credentials.cert || ''}
              onChange={(e) => setCredentials({ ...credentials, cert: e.target.value })}
              margin="normal"
            />
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Client Key (Optional)"
              value={credentials.key || ''}
              onChange={(e) => setCredentials({ ...credentials, key: e.target.value })}
              margin="normal"
            />
          </Box>
        );
      
      default:
        return (
          <Box>
            <TextField
              fullWidth
              label="Connection Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              margin="normal"
              required
            />
            <Alert severity="info" sx={{ mt: 2 }}>
              This provider is a placeholder. You can add the connection, but it will return demo data.
            </Alert>
          </Box>
        );
    }
  };

  const getStepContent = (step) => {
    switch (step) {
      case 0:
        return (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            <FormControl fullWidth margin="normal">
              <InputLabel>Select Cloud Provider</InputLabel>
              <Select
                value={provider}
                onChange={(e) => setProvider(e.target.value)}
                label="Select Cloud Provider"
              >
                {providerOptions.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label} {option.functional ? '✅' : '(Demo)'}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            {provider && (
              <Alert severity="info" sx={{ mt: 2 }}>
                {providerOptions.find(p => p.value === provider)?.functional
                  ? '✅ This provider is fully functional'
                  : '⚠️ This provider is a placeholder and will return demo data'}
              </Alert>
            )}
          </motion.div>
        );
      case 1:
        return (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            {renderProviderForm()}
          </motion.div>
        );
      case 2:
        return (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            <Typography variant="h6" gutterBottom>
              Review and Connect
            </Typography>
            <Typography variant="body1">Provider: {provider}</Typography>
            <Typography variant="body1">Name: {name}</Typography>
            {region && <Typography variant="body1">Region: {region}</Typography>}
            <Alert severity="warning" sx={{ mt: 2 }}>
              Click "Connect" to establish the connection to {provider}
            </Alert>
            {error && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}
          </motion.div>
        );
      default:
        return 'Unknown step';
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Add New Cloud Connection</DialogTitle>
      <DialogContent>
        <Stepper activeStep={activeStep} sx={{ pt: 3, pb: 5 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
        <AnimatePresence mode="wait">
          {getStepContent(activeStep)}
        </AnimatePresence>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Box sx={{ flex: '1 1 auto' }} />
        <Button disabled={activeStep === 0} onClick={handleBack}>
          Back
        </Button>
        {activeStep === steps.length - 1 ? (
          <Button 
            onClick={handleConnect} 
            variant="contained"
            disabled={loading || !name}
          >
            {loading ? 'Connecting...' : 'Connect'}
          </Button>
        ) : (
          <Button 
            onClick={handleNext} 
            variant="contained"
            disabled={activeStep === 0 && !provider}
          >
            Next
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default WizardConector;
