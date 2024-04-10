import { Container, Flex } from "@chakra-ui/react";
import CompCard from "../component/compcard";


export default function TransferPage() {
    return (
        <Container maxW={"100%"} py={4} bg={"#f8f8f8"} boxShadow={"0 2px 2px rgba(0, 0, 0, 0)"} borderRadius={8}>
            <Flex flexDirection={"column"} justifyContent={"center"} alignItems={"center"}>
                <CompCard />
            </Flex>
        </Container>
    )
}