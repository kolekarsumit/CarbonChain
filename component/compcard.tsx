import { useAddress, useContract, useContractRead } from "@thirdweb-dev/react";
import { CONTRACT_ADDRESS } from "../consts/addresses";
import { Card } from "@chakra-ui/react";

export default function CompCard(){

    const address= useAddress();

    const {
        contract
    }= useContract(CONTRACT_ADDRESS);

    const {
        data: verifiedComp,
        isLoading: isVerfiedComploading
    }=useContractRead(contract,
        "getAllCompanies");


        console.log(verifiedComp);


        return(
            <Card w={"50%"} p={20}>

                
            </Card>
        )
}