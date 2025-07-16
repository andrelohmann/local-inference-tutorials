# Migration Notice: Model Directory Changed

## What Changed
The model storage location has been moved from `./models/` to `~/.models/` in your home directory.

## Why This Change
- **Shared Storage**: Models can now be reused across multiple projects
- **Repository Cleanliness**: Large model files are no longer part of the repository
- **User-centric**: Follows common practice for user-specific data storage
- **Better Organization**: Separates code from data

## Migration Steps

### If you have existing models in ./models/
```bash
# Move existing models to new location
mkdir -p ~/.models
mv ./models/* ~/.models/
rmdir ./models  # Remove empty directory
```

### If you're starting fresh
No action needed - the setup script will automatically create `~/.models/` and download the model there.

## Benefits
- **Disk Space**: No duplicate models across projects
- **Maintenance**: Easier model management across different setups
- **Compatibility**: Standard location for user-specific data
- **Backup**: Easier to backup just the ~/.models directory

## Location Reference
- **Old location**: `./models/devstral-q4_k_m.gguf`
- **New location**: `~/.models/devstral-q4_k_m.gguf`
- **Container path**: `/models/devstral-q4_k_m.gguf` (unchanged)
