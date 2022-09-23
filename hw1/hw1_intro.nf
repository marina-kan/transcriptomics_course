#!/usr/bin/env nextflow

params.SRA_acc_list = "filename.txt"
params.results_dir = "results/multiqc_report/"

log.info ""
log.info "  Q U A L I T Y   C O N T R O L  "
log.info "================================="
log.info "SRA numbers in file        : ${params.SRA_acc_list}"
log.info "Results location   : ${params.results_dir}"

File acc_list = new File(params.SRA_acc_list)
SRA_list = acc_list.getText('UTF-8').split("\n")

process DownloadFastQ {
  input:
    val sra_acc

  output:
    path "${sra_acc}/*"

  script:
    """
    fasterq-dump --split-files -O ${sra_acc}/ ${sra_acc} 
    gzip -r ${sra_acc}/
    """
}

process RunFastQC {
  input:
    path fastq_files

  output:
    path "qc/*"

  script:
    """
    mkdir qc
    fastqc -o qc $fastq_files
    """
}

process RunMultiQC {
publishDir "${params.results_dir}"
  input:
    path fastqc_out
  output:
    path "multiqc_report.html"
  script:
    """
    multiqc ${fastqc_out}
    """
}

workflow {
  data = Channel.of( SRA_list )
  DownloadFastQ(data)
  RunFastQC( DownloadFastQ.out )
  RunMultiQC( RunFastQC.out.collect() )
}
