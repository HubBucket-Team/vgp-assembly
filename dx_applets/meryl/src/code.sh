#!/bin/bash
# meryl 0.0.1
# Generated by dx-app-wizard.

set -x -e -o pipefail


main() {

    sudo chmod 777 /usr/bin/meryl

    echo "Value of fastq: '${fastq[@]}'"
	echo "Value of kmer: '$kmer'"

    for i in ${!fastq[@]}
    do
        
		one_fastq_jobs+=($(dx-jobutil-new-job -ikmer="$kmer" -ifastq="${fastq[$i]}" meryl_fastq))
        
    done
 
	printf -v ids_d ' %s:fastq_meryl' "${one_fastq_jobs[@]}"
	ids_d=${ids_d:1}
    
    echo $ids_d

    for one_fastq_jobs in "${one_fastq_jobs[@]}"; do 
        merge_fastq_args+=(-icount_kmer="$one_fastq_jobs":fastq_meryl)
    done

    merge_job=$(dx-jobutil-new-job "${merge_fastq_args[@]}" -ikmer="$kmer"  union_meryl)
    dx-jobutil-add-output meryl_intermediate_file "$merge_job":meryl_intermediate_file --class=jobref

}

union_meryl(){

    sudo chmod 777 /usr/bin/meryl
    mkdir all_count
    cd all_count

    for i in $(dx ls); do 
        ending=$(echo "$i" | grep '/$' || echo ""); 
        if [ -n "$ending" ]; then 
            meryl_count_kmer+=($ending)
            dx download -r "$ending" 
        fi 
    done

                
    ulimit -Sn 32000
    meryl union-sum output union_meryl "${meryl_count_kmer[@]}"
   
    meryl histogram union_meryl | sed 's/\t/ /g' > union_meryl.hist
    
    echo union_meryl.hist
    
    cd ~
    mv all_count temp_all_count
    mkdir all_count
    mv temp_all_count/union_meryl all_count
    rm -r temp_all_count
    tar -cvf seq_meryl_files.tar all_count/
    mkdir -p ~/out/meryl_intermediate_file
    mv seq_meryl_files.tar ~/out/meryl_intermediate_file
    dx-upload-all-outputs --parallel

}

meryl_fastq() {
	
	sudo chmod 777 /usr/bin/meryl

	mem_in_gb=`head -n1 /proc/meminfo | awk '{print int($2*0.8/1024/1024)}'`
	echo $mem_in_gb
	
    dx-download-all-inputs

	mkdir -p ~/out/fastq_meryl/
	
	meryl count k="$kmer" output ~/out/fastq_meryl/${fastq_prefix}.meryl "${fastq_path}" memory=$mem_in_gb

    dx-upload-all-outputs --parallel
}