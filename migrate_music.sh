#!/bin/bash

SOURCE_DIR="/Volumes/INTENSO/MUSIC BACKUP/"
DEST_DIR="$HOME/Music/MaCoffee Library/"
CORRUPT_LOG="$HOME/Desktop/corrupted_tracks.log"

echo "Phase 1: High-Speed Triage - Phase A - 0 Error pass"
echo "=============================================================================="

echo "--- Sweep Run: $(date) ---" >> "$CORRUPT_LOG"

cd "$SOURCE_DIR" || { echo "❌ Error: Source directory not found!"; exit 1; }

find . -type f | while read -r filepath; do
    
    mkdir -p "$DEST_DIR/$(dirname "$filepath")"
    
    # 1. Skip permanently if already logged as corrupt
    if [ -f "$CORRUPT_LOG" ] && grep -qxF "$filepath" "$CORRUPT_LOG"; then
        continue
    fi
    
    # 2. Skip if the final audio file already exists cleanly
    if [ -f "$DEST_DIR/$filepath" ] && [ ! -f "$DEST_DIR/$filepath.map" ]; then
        continue
    fi
    
    # 3. FRESH SLATE: Delete any old map files
    rm -f "$DEST_DIR/$filepath.map"
    
    echo "Sweeping: $filepath"
    
    # Run exact user command wrapped in timeout watchdog
    timeout 15s ddrescue --no-scrape --no-trim -e 1 --skip-size=10000000 --unidirectional  "$filepath" "$DEST_DIR/$filepath" "$DEST_DIR/$filepath.map"
    
    EXIT_CODE=$?
    
    # Check if drive disconnected
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "🚨 CRITICAL ERROR: The hard drive disconnected from the Mac!"
        rm -f "$DEST_DIR/$filepath.map" 
        exit 1
    fi
    
    # WATCHDOG TIMEOUT CHECK (Exit code 124)
    if [ $EXIT_CODE -eq 124 ]; then
        echo "   ⏱️ Watchdog Timeout (Too slow). Quarantined and logged."
        grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
        rm -f "$DEST_DIR/$filepath.map"
        continue
    fi
    
    # TRUE VALIDATION LOGIC:
    # Check if the map file indicates actual unread/bad sectors (- or * or ? in data blocks)
    # If the file is 100% clean, ddrescue's mapfile won't have active error flags.
    if [ -f "$DEST_DIR/$filepath.map" ]; then
        # Look specifically for unrecovered bad sectors (-) or failed non-trimmed blocks (*) in the mapfile data sections
        if grep -qE '^\s*[0-9]+\s+[0-9]+\s+[-*?]' "$DEST_DIR/$filepath.map"; then
            echo "   ❌ Damaged Sector. Quarantined and logged."
            grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
        else
            # Clean map file (100% recovered despite pass steps)
            rm -f "$DEST_DIR/$filepath.map"
            echo "   ✅ 100% Perfect!"
        fi
    else
        echo "   ✅ 100% Perfect!"
    fi
    
done

echo "=============================================================================="
echo "✅ Phase 1 Complete!"





# working but falsly classifiying as "corrupted" files with 0 errors
# echo "Phase 1: High-Speed Triage (Watchdog Timer Enabled)"
# echo "=============================================================================="

# echo "--- Sweep Run: $(date) ---" >> "$CORRUPT_LOG"

# cd "$SOURCE_DIR" || { echo "❌ Error: Source directory not found!"; exit 1; }

# find . -type f | while read -r filepath; do
    
#     mkdir -p "$DEST_DIR/$(dirname "$filepath")"
    
#     # 1. Skip permanently if already logged as corrupt
#     if [ -f "$CORRUPT_LOG" ] && grep -qxF "$filepath" "$CORRUPT_LOG"; then
#         continue
#     fi
    
#     # 2. Skip if the final audio file already exists cleanly
#     if [ -f "$DEST_DIR/$filepath" ] && [ ! -f "$DEST_DIR/$filepath.map" ]; then
#         continue
#     fi
    
#     # 3. FRESH SLATE: Delete any old map files
#     rm -f "$DEST_DIR/$filepath.map"
    
#     echo "Sweeping: $filepath"
    
#     # RUN DDRESCUE IN THE BACKGROUND WITH A WATCHDOG TIMER:
#     # We strip out min-read-rate so small files don't panic.
#     # Instead, we give it max 15 seconds per file via timeout.
#     # --min-read-rate=100000 -> good but throws errors where we have healthy files !!!!
    
#     timeout 15s ddrescue --no-scrape --no-trim -e 1  --skip-size=10000000 --unidirectional  "$filepath" "$DEST_DIR/$filepath" "$DEST_DIR/$filepath.map"
    
#     EXIT_CODE=$?
    
#     # Check if drive disconnected
#     if [ ! -d "$SOURCE_DIR" ]; then
#         echo "🚨 CRITICAL ERROR: The hard drive disconnected from the Mac!"
#         rm -f "$DEST_DIR/$filepath.map" 
#         exit 1
#     fi
    
#     # TIMEOUT CHECK (Exit code 124 means the 'timeout' command killed it because it took > 15 seconds)
#     if [ $EXIT_CODE -eq 124 ]; then
#         echo "   ⏱️ Too slow / Hanging. Quarantined and logged."
#         grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
#         continue
#     fi
    
#     # MAPFILE VALIDATION LOGIC:
#     if [ -f "$DEST_DIR/$filepath.map" ]; then
#         if grep -qE '[-?]' "$DEST_DIR/$filepath.map"; then
#             echo "   ❌ Damaged / Incomplete. Quarantined and logged."
#             grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
#         else
#             rm -f "$DEST_DIR/$filepath.map"
#             echo "   ✅ 100% Perfect!"
#         fi
#     else
#         echo "   ✅ 100% Perfect!"
#     fi
    
# done

# echo "=============================================================================="
# echo "✅ Phase 1 Complete!"




## working last 23.22 9 aug 2026
# echo "Phase 1: High-Speed Triage (Raw Byte Speed Limit Without Scrape of Trim"
# echo "Aborting instantly on errors or speeds below 100,000 bytes/sec."
# echo "=============================================================================="

# echo "--- Sweep Run: $(date) ---" >> "$CORRUPT_LOG"
# cd "$SOURCE_DIR" || exit

# find . -type f | while read -r filepath; do
#     mkdir -p "$DEST_DIR/$(dirname "$filepath")"
    
#     if [ -f "$CORRUPT_LOG" ] && grep -qxF "$filepath" "$CORRUPT_LOG"; then
#         continue
#     fi
    
#     if [ -f "$DEST_DIR/$filepath" ] && [ ! -f "$DEST_DIR/$filepath.map" ]; then
#         continue
#     fi
    
#     echo "Sweeping: $filepath"
    
#     # ddrescue -n -e 1 --min-read-rate=100000 --skip-size=10000000 --unidirectional "$filepath" "$DEST_DIR/$filepath" "$DEST_DIR/$filepath.map"
#     ddrescue --no-scrape --no-trim -e 1 --min-read-rate=100000 --skip-size=10000000 --unidirectional  "$filepath" "$DEST_DIR/$filepath" "$DEST_DIR/$filepath.map"
#     if [ $? -ne 0 ] || grep -qE '[-?]' "$DEST_DIR/$filepath.map"; then
        
#         if [ ! -d "$SOURCE_DIR" ]; then
#             echo "🚨 CRITICAL ERROR: The hard drive disconnected from the Mac!"
#             rm -f "$DEST_DIR/$filepath.map" 
#             exit 1
#         fi
        
#         echo "   ❌ Slow/Corrupt. Aborted and logged."
#         grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
#     else
#         rm -f "$DEST_DIR/$filepath.map"
#     fi
# done

# echo "=============================================================================="
# echo "✅ Sweep Complete."




# echo "Phase 1: High-Speed Triage"
# echo "Aborting instantly on any errors. Saving healthy files only."
# echo "=============================================================================="

# echo "--- Fast Sweep Run: $(date) ---" >> "$CORRUPT_LOG"
# cd "$SOURCE_DIR" || exit

# find . -type f | while read -r filepath; do
#     mkdir -p "$DEST_DIR/$(dirname "$filepath")"
    
#     # Skip if already logged as corrupt
#     if [ -f "$CORRUPT_LOG" ] && grep -qxF "$filepath" "$CORRUPT_LOG"; then
#         continue
#     fi
    
#     # Skip if finished perfectly
#     if [ -f "$DEST_DIR/$filepath" ] && [ ! -f "$DEST_DIR/$filepath.map" ]; then
#         continue
#     fi
    
#     echo "Sweeping: $filepath"
    
#     # THE MAGIC FLAGS:
#     # -n (no scrape)
#     # -e 1 (exit immediately on 1 error)
#     # -T 30s (exit if the drive freezes for 30 seconds)
#     ddrescue -n -e 1 -T 30s  "$filepath" "$DEST_DIR/$filepath" "$DEST_DIR/$filepath.map"
    
#     # If ddrescue exited with an error OR a bad sector was mapped
#     if [ $? -ne 0 ] || grep -qE '[-?]' "$DEST_DIR/$filepath.map"; then
#         echo "   ❌ Corrupt/Frozen. Aborted and logged."
#         grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
#     else
#         # Perfect file! Clean the map.
#         rm -f "$DEST_DIR/$filepath.map"
#     fi
# done

# echo "=============================================================================="
# echo "✅ Phase 1 Complete. Review $CORRUPT_LOG on your Desktop."


## end of working version--


##--older_----

# echo "Starting fully automated ddrescue transfer..."
# echo "Logging corrupted files to: $CORRUPT_LOG"
# echo "=============================================================================="

# echo "--- Rescue Run: $(date) ---" >> "$CORRUPT_LOG"

# cd "$SOURCE_DIR" || exit

# find . -type f | while read -r filepath; do
    
#     mkdir -p "$DEST_DIR/$(dirname "$filepath")"
    
#     # THE INCREMENTAL FIX: 
#     # Skip ONLY if the file exists AND the map file does NOT exist.
#     # (If the map file exists, it means the previous transfer was interrupted 
#     # or had bad sectors, so we let ddrescue resume it using the map file!)
#     if [ -f "$DEST_DIR/$filepath" ] && [ ! -f "$DEST_DIR/$filepath.map" ]; then
#         continue
#     fi
    
#     echo "Copying: $filepath"
    
#     # Run the safe pass (it will automatically resume if a .map file exists)
#     ddrescue -n "$filepath" "$DEST_DIR/$filepath" "$DEST_DIR/$filepath.map"
    
#     # Check the map file for errors
#     if grep -qE '[-?]' "$DEST_DIR/$filepath.map"; then
#         echo "   ⚠️ Bad sectors found. Logging to list..."
#         # Add the file path to your central log file (ignoring duplicates)
#         grep -qxF "$filepath" "$CORRUPT_LOG" || echo "$filepath" >> "$CORRUPT_LOG"
#     else
#         # Clean up the map file if the track is 100% perfect
#         rm -f "$DEST_DIR/$filepath.map"
#     fi
    
# done

# echo "=============================================================================="
# echo "✅ Batch complete!"
