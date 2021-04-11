
printf "Output of zonation test: \n"

curl --header "Content-Type: application/json"   --request POST   --data '{"id":"125.123.199.5","function_to_run":"zonation","zon_n_t_segs":"3","Ea":"250000","D0":"3e-9","U38Pb06":"[[30,40]]","sigU38Pb06":"[[3,4]]","Lmax":"3.0","tmax":"1e9","tmin":"1e5","dr":"0.1","distance":"[1.0,2.0,3.0]"}'   http://localhost:8000/model

printf "\n\nPercent progress of inversion:\n"

curl --header "Content-Type: application/json"   --request POST   --data '{"id":"125.123.199.5"}' http://localhost:8000/progress
printf "\n"
