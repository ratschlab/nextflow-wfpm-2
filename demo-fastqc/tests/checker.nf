#!/usr/bin/env nextflow

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2
version = '0.1.0'  // package version

container = [
    'github.com': 'github.com/nextflow-wfpm-2.demo-fastqc'
]
default_container_registry = 'github.com'
/********************************************************************/

// universal params
params.container_registry = ""
params.container_version = ""
params.container = ""


// tool specific parmas go here, add / change as needed
params.input_file = ""
params.expected_output = ""

include { demoFastqc } from '../demo-fastqc' params(['cleanup': false, *:params])

Channel
  .fromPath(params.input_file, checkIfExists: true)
  .set { input_file }


process file_smart_diff {
  container "${params.container ?: container[params.container_registry ?: default_container_registry]}:${params.container_version ?: version}"

  input:
    path output_file
    path expected_file

  output:
    stdout()

  script:
    """
    # Note: this is only for demo purpose, please write your own 'diff' according to your own needs.
    # remove date field before comparison eg, <div id="header_filename">Tue 19 Jan 2021<br/>test_rg_3.bam</div>
    # sed -e 's#"header_filename">.*<br/>test_rg_3.bam#"header_filename"><br/>test_rg_3.bam</div>#'
    diff <( cat ${output_file} | sed -e 's#"header_filename">.*<br/>#"header_filename"><br/>#' ) \
         <( ([[ '${expected_file}' == *.gz ]] && gunzip -c ${expected_file} || cat ${expected_file}) | sed -e 's#"header_filename">.*<br/>#"header_filename"><br/>#' ) \
    && ( echo "Test PASSED" && exit 0 ) || ( echo "Test FAILED, output file mismatch." && exit 1 )
    """
}


workflow checker {
  take:
    input_file
    expected_output

  main:
    demoFastqc(
      input_file
    )

    file_smart_diff(
      demoFastqc.out.output_file,
      expected_output
    )
}


workflow {
  checker(
    file(params.input_file),
    file(params.expected_output)
  )
}
