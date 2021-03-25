#!/bin/bash

#string='Version: "0.8.0-aplha"';
string='Version: "0.8.0-aplha.91.xx"';

if [[ $string =~ "-" ]]; then
   echo "It's there!"
else
  echo "not found"
fi
