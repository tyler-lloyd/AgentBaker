#! /bin/bash

SRC=/var/log/containers
DST=/var/log/azure/aks/pods

shopt -s extglob
shopt -s nullglob
mkdir -p $DST

# Remove any existing logs as they may be outdated
rm -f $DST/*

# Manually sync all matching logs once
for TUNNEL_LOG_FILE in $(compgen -G "$SRC/@(aks-link|konnectivity|tunnelfront)-*_kube-system_*.log"); do
   echo "Linking $TUNNEL_LOG_FILE"
   /bin/ln -Lf $TUNNEL_LOG_FILE $DST/
done
echo "Starting inotifywait..."

# Monitor for changes
inotifywait -q -m -r -e delete,create $SRC | while read DIRECTORY EVENT FILE; do
    case $FILE in
        aks-link-*_kube-system_*.log | konnectivity-*_kube-system_*.log | tunnelfront-*_kube-system_*.log)
            case $EVENT in
                CREATE*)
                    echo "Linking $FILE"
                    /bin/ln -Lf "$DIRECTORY/$FILE" "$DST/$FILE"
                    ;;
                DELETE*)
                    echo "Removing $FILE"
                    rm -f "$DST/$FILE"
                    ;;
            esac;;
    esac
done