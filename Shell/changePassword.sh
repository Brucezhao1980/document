#!/bin/bash


for i in `cat ip.txt`
do
ssh $i passwd root --stdin < ./password.txt
done
