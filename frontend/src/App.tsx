import {Button} from "@/components/ui/button.tsx";
import {useEffect, useState} from "react";

function App() {
    const [counter, setCounter] = useState(0);
    const [msg, setMsg] = useState<string>("");
    const incrementCounter = () => {
        setCounter(counter+1);
    }
    useEffect(() => {
        fetch("/api/")
            .then(res => res.text())
            .then(setMsg)
            .catch(error=>setMsg(`error: ${error}`))
    }, []);
    return (
        <div className={"w-full h-screen bg-background overflow-hidden flex justify-center items-center"}>
            <div className={"flex flex-col gap-4 items-center"}>
                <h1 className={"text-primary text-3xl font-bold"}>Hello world</h1>
                <Button
                    onClick={incrementCounter}
                >Increment me {counter}</Button>
                <p>Message from the server:</p>
                <p>{msg}</p>
            </div>
        </div>
    )
}

export default App
