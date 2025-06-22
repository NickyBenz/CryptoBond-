import { useNavigate } from "react-router-dom";
const ErrorPage = () => {
    const navigate = useNavigate()

    function Exit(){
        navigate('/')
    }
  return (
    <div>
      <h1>Error!</h1>
      <p>There was an issue with your transaction. Please try again.</p>
      <button onClick={Exit}>Leave</button>
    </div>
  );
};

export default ErrorPage;