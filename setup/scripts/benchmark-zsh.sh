#!/bin/bash

# Benchmark zsh startup time
echo "🚀 Benchmarking zsh startup time..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run zsh-bench if available
if command -v zsh-bench >/dev/null 2>&1; then
    echo "📊 Running zsh-bench (comprehensive benchmark)..."
    zsh-bench
    echo ""
fi

# Simple time measurement
echo "⏱️  Simple startup time measurement (5 runs)..."
echo "Running: time zsh -i -c exit (5 times)"

total=0
for i in {1..5}; do
    result=$( (time zsh -i -c exit) 2>&1 | grep real | awk '{print $2}' | sed 's/[ms]//g')
    echo "Run $i: ${result}s"
    # Convert to seconds for easier math (handle format like 0m0.765s)
    if [[ $result == *m* ]]; then
        minutes=$(echo "$result" | cut -d'm' -f1)
        seconds=$(echo "$result" | cut -d'm' -f2)
        result=$(echo "$minutes * 60 + $seconds" | bc -l 2>/dev/null || awk "BEGIN {print $minutes * 60 + $seconds}")
    fi
    total=$(echo "$total + $result" | bc -l 2>/dev/null || awk "BEGIN {print $total + $result}")
done

average=$(echo "scale=3; $total / 5" | bc -l 2>/dev/null || awk "BEGIN {printf \"%.3f\", $total / 5}")
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 Average startup time: ${average}s"

echo ""
echo "💡 To see detailed profiling, start a new zsh session and run 'zprof'"
echo "💡 zprof is now enabled in your .zshrc"