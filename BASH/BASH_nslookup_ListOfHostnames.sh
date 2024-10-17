for Item in  'prodfwcareagr' 'pdboscrmdbagr' 'pdbosdbagro.a' 'pdgbrcrmdbagr' 'pdgbrdbagro.a' 'pditucrmdbagr' 'pditudbagro.a' 'pdtaxdbagro.a' 'pibosdbag.aws' 'd3qataxdb01.a' 'qabosdbag.aws' 'fwrepsql' 'g0pigssdb01' 'g1piefwrepsql' 'g1piefwsql' 'g1qa3ipssql01' 'g2qa3ipsnrt01' 'gdcqa3sqlrep0' 'gdcqa4sqlrep0' 'gdcqa3sql' ''g0q3lgynrtdb0' 'g0qagssdb01'g0qafwrepsql' 'g0qafwsql' 'g2qa4ipsnrt01' 'g2q4necsql01' 'g0q4lgynrtdb0' 'g2qa4ipssql01' 'g0qagssdb01' 'g2qa4ipssql01';
    do
        nslookup "$Item" | grep -v -e '#53'$ | grep Address
    done