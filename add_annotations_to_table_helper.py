#!/usr/bin/env python

import sys
import os
import re
from cyvcf2 import VCF
import tempfile
import csv

def parse_csq_header(vcf_file):
    for header in vcf_file.header_iter():
        info = header.info(extra=True)
        if b'ID' in info.keys() and info[b'ID'] == b'CSQ':
            format_pattern = re.compile('Format: (.*)"')
            match = format_pattern.search(info[b'Description'].decode())
            return match.group(1).split('|')

def parse_csq_entries(csq_entries, csq_fields):
    transcripts = []
    for entry in csq_entries:
        values = entry.split('|')
        transcript = {}
        for key, value in zip(csq_fields, values):
            transcript[key] = value
        transcripts.append(transcript)
        if transcript['PICK'] == '1':
            return transcript
    return transcripts[0]

(script, tsv_filename, vcf_filename, vep_fields, output_dir) = sys.argv
vep_fields_list = vep_fields.split(',')

vcf_file = VCF(vcf_filename)

csq_fields = parse_csq_header(vcf_file)

vep = {}
for variant in vcf_file:
    chr = str(variant.CHROM)
    pos = str(variant.POS)
    ref = str(variant.REF)

    if chr not in vep:
        vep[chr] = {}

    if pos not in vep[chr]:
        vep[chr][pos] = {}

    if ref not in vep[chr][pos]:
        csq = variant.INFO.get('CSQ')
        if csq is not None:
            vep[chr][pos][ref] = parse_csq_entries(csq.split(','), csq_fields)
        else:
            vep[chr][pos][ref] = None
    else:
        sys.exit("VEP entry for at CHR %s, POS %s, REF %s already exists" % (chr, pos, ref) )


with open(tsv_filename, 'r') as input_filehandle:
    reader = csv.DictReader(input_filehandle, delimiter = "\t")
    output_filehandle = open(os.path.join(output_dir, 'variants.annotated.tsv'), 'w')
    writer = csv.DictWriter(output_filehandle, fieldnames = reader.fieldnames + vep_fields_list, delimiter = "\t")
    writer.writeheader()
    for entry in reader:
        row = entry
        for field in vep_fields_list:
            vep_annotations = vep[entry['CHROM']][entry['POS']][entry['REF']]
            if vep_annotations is not None and field in vep_annotations:
                row[field] = vep_annotations[field]
            else:
                row[field] = '-'
        writer.writerow(row)
    output_filehandle.close()
