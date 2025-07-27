#!/bin/bash

MASTER="pve01"

if [ "$HOSTNAME" != "$MASTER" ]; then
    echo "🔗 Rejoin cluster via $MASTER"
    pvecm add $MASTER
else
    echo "✅ Nœud maître détecté → pas de join nécessaire"
fi
