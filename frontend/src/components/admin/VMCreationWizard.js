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
  Alert,
  Slider
} from '@mui/material';
import { motion, AnimatePresence } from 'framer-motion';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || '';

const steps = ['Basic Configuration', 'Resources', 'Review & Create'];

const imageOptions = [
  { value: 'ubuntu:22.04', label: 'Ubuntu 22.04 LTS' },
  { value: 'ubuntu:20.04', label: 'Ubuntu 20.04 LTS' },
  { value: 'debian:11', label: 'Debian 11' },
  { value: 'debian:12', label: 'Debian 12' },
  { value: 'alpine:3.18', label: 'Alpine Linux 3.18' },
  { value: 'centos:8', label: 'CentOS 8' },
  { value: 'fedora:38', label: 'Fedora 38' },
];

const VMCreationWizard = ({ open, onClose, connectionId, onSuccess }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [name, setName] = useState('');
  const [image, setImage] = useState('ubuntu:22.04');
  const [cpuCount, setCpuCount] = useState(2);
  const [memoryMb, setMemoryMb] = useState(2048);
  const [diskGb, setDiskGb] = useState(20);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleNext = () => {
    if (activeStep === 0 && !name) {
      setError('VM name is required');
      return;
    }
    setError('');
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleCreate = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await axios.post(
        `${API_BASE_URL}/api/v1/admin/cloud_connections/${connectionId}/nodes`,
        {
          name,
          image,
          cpu_count: cpuCount,
          memory_mb: memoryMb,
          disk_gb: diskGb,
          config: {}
        }
      );

      if (onSuccess) {
        onSuccess(response.data);
      }
      
      handleClose();
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create VM');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setActiveStep(0);
    setName('');
    setImage('ubuntu:22.04');
    setCpuCount(2);
    setMemoryMb(2048);
    setDiskGb(20);
    setError('');
    onClose();
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
            <TextField
              fullWidth
              label="VM Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              margin="normal"
              required
              helperText="Enter a unique name for your VM/Container"
            />
            <FormControl fullWidth margin="normal">
              <InputLabel>Operating System Image</InputLabel>
              <Select
                value={image}
                onChange={(e) => setImage(e.target.value)}
                label="Operating System Image"
              >
                {imageOptions.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </motion.div>
        );
      case 1:
        return (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            <Box sx={{ mt: 2, mb: 3 }}>
              <Typography gutterBottom>CPU Cores: {cpuCount}</Typography>
              <Slider
                value={cpuCount}
                onChange={(e, newValue) => setCpuCount(newValue)}
                min={1}
                max={16}
                step={1}
                marks
                valueLabelDisplay="auto"
              />
            </Box>
            <Box sx={{ mt: 2, mb: 3 }}>
              <Typography gutterBottom>Memory: {memoryMb} MB ({(memoryMb / 1024).toFixed(1)} GB)</Typography>
              <Slider
                value={memoryMb}
                onChange={(e, newValue) => setMemoryMb(newValue)}
                min={512}
                max={16384}
                step={512}
                valueLabelDisplay="auto"
              />
            </Box>
            <Box sx={{ mt: 2, mb: 3 }}>
              <Typography gutterBottom>Disk Size: {diskGb} GB</Typography>
              <Slider
                value={diskGb}
                onChange={(e, newValue) => setDiskGb(newValue)}
                min={10}
                max={500}
                step={10}
                valueLabelDisplay="auto"
              />
            </Box>
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
              Review Configuration
            </Typography>
            <Box sx={{ mt: 2 }}>
              <Typography><strong>Name:</strong> {name}</Typography>
              <Typography><strong>Image:</strong> {image}</Typography>
              <Typography><strong>CPU Cores:</strong> {cpuCount}</Typography>
              <Typography><strong>Memory:</strong> {memoryMb} MB ({(memoryMb / 1024).toFixed(1)} GB)</Typography>
              <Typography><strong>Disk:</strong> {diskGb} GB</Typography>
            </Box>
            <Alert severity="info" sx={{ mt: 2 }}>
              Click "Create VM" to provision your new virtual machine. This may take a few moments.
            </Alert>
          </motion.div>
        );
      default:
        return 'Unknown step';
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Create New VM/Container</DialogTitle>
      <DialogContent>
        <Stepper activeStep={activeStep} sx={{ pt: 3, pb: 5 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <AnimatePresence mode="wait">
          {getStepContent(activeStep)}
        </AnimatePresence>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={loading}>
          Cancel
        </Button>
        {activeStep > 0 && (
          <Button onClick={handleBack} disabled={loading}>
            Back
          </Button>
        )}
        {activeStep < steps.length - 1 ? (
          <Button onClick={handleNext} variant="contained" disabled={loading}>
            Next
          </Button>
        ) : (
          <Button onClick={handleCreate} variant="contained" disabled={loading}>
            {loading ? 'Creating...' : 'Create VM'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default VMCreationWizard;
