import {usePlayer, useStage, useRound, useGame } from "@empirica/core/player/classic/react";
import { Loading } from "@empirica/core/player/react";
import React, {useState, useRef, useEffect } from "react";
import { Opinion } from "./Opinion";
import { InputBox } from "./InputBox";
import { Avatar } from "./Avatar";
import { useSpring, animated } from 'react-spring';



export function Chat({ scope, attribute, loading}) {
    const player = usePlayer();
    const round = useRound();
    const stage = useStage();
    const game = useGame()
    const { condition } = game.get("treatment");

    if (!scope || !player) {
        return <LoadingComp />;
    }
//*
// Save messages to scope, for the players and the researchers
//*
    const handleNewMessage = (text) => {
        console.log("scope", scope, scope.append)
        scope.append(attribute, {
            text,
            likes : {},
            time: Date.now(),
            round: round.get('idx'),
            recipient: player.get("recipient"),
            sender: {
                id: player.id,
                name: player.get("name") || player.id,
                avatar: player.get("avatar"),
            },
        });
        const playerStageData = scope.getAttribute(attribute)?.items || [];
        game.set("messages", playerStageData.map((msg, i) => msg.val._value));
    };

//*
// Give players access to the messages from scope using the functions further down
//*

    let msgs = scope.getAttribute(attribute)?.items || [];
    console.log("msg", msgs)
    if(stage.get('name') == 'send') {
        return (
            <div className="w-100 h-full pb-1/10 pt-1/10 absolute justify-center items-center flex flex-col">
              <h2 className="align-left"> Messages <b>sent</b>:</h2>
              <MessagesPanel scope={scope} msgs={msgs} stage={stage}
                             round={round} player={player} condition={condition}/>

              {
                condition == 'slider' ?
                 null :
                  <InputBox onNewMessage={handleNewMessage} buttonStyles='w-9 h-9 p-2 text-sm'/>
              }
            </div>
        );
    } else {
        return (
            <div className="w-100 h-full pb-1/10 pt-1/10 absolute justify-center items-center flex flex-col">
              <h2>Messages <b>received</b>: </h2>
              <MessagesPanel scope={scope} msgs={msgs} stage={stage}
                             round={round} player={player} condition={condition}/>
              {
                player.stage && player.stage.get("submit") ?
                <div> Thank you for your answer. The next stage will start when all the other players have submitted their answer. </div> :
                 <div className="h-1/4">
       
      </div>
              }
            </div>
        );
    }
}

function Message(props) {
    const animationProps = useSpring({ opacity: 1, from: { opacity: 0 } });

    return (
        <animated.div style={animationProps}>
            <MessageComp {...props} />
        </animated.div>
    );
}

//*
// MessagePanel shows the messages based on the following condition filters
//*


function MessagesPanel(props) {
    let {player, stage, round, scope, msgs, condition } = props;
    const scroller = useRef(null);
    const [msgCount, setMsgCount] = useState(0);
    const msgsFiltered = condition === 'interactive'
  ? interactiveFilter()
  : (stage.get('name') === 'send' && condition === 'unidirectional'
    ? unidirectionalFilter()
    : (stage.get('name')=== 'observe' && condition === 'slider')
     ? sliderFilter()
     : otherwiseFilter());

function interactiveFilter() {
  return msgs.filter(msg => msg.value.sender.id === player.id || msg.value.recipient === player.id)
    .filter(msg => msg.value.round === round.get('idx'));
}

function unidirectionalFilter() {
  return msgs.filter(msg => msg.value.sender.id === player.id)
    .filter(msg => msg.value.round === round.get('idx'));
}

function sliderFilter() {
  return msgs.filter(msg => msg.value.recipient === player.id)
    .filter(msg => msg.value.round + 1 === round.get('idx'));
}

function otherwiseFilter() {
  return msgs.filter(msg => msg.value.recipient === player.id)
    .filter(msg => msg.value.round === round.get('idx'));
}

//*
// Scrollbar for the message panel
//*

    useEffect(() => {
        if (!scroller.current) {
            return;
        }
        if (msgCount !== msgs.length) {
            setMsgCount(msgs.length);
            scroller.current.scrollTop = scroller.current.scrollHeight;
        }
    }, [scroller, props, msgCount]);

//*
// Before messages are sent the panel shows this
//*
    if (msgsFiltered.length === 0) {
        return (<div className="h-full w-full flex justify-center items-center">
        <div className="flex flex-col justify-center items-center w-2/3 space-y-2">
          <div className="w-24 h-24 text-gray-200">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-full w-full fill-current" viewBox="0 0 512 512">
              <path d="M123.6 391.3c12.9-9.4 29.6-11.8 44.6-6.4c26.5 9.6 56.2 15.1 87.8 15.1c124.7 0 208-80.5 208-160s-83.3-160-208-160S48 160.5 48 240c0 32 12.4 62.8 35.7 89.2c8.6 9.7 12.8 22.5 11.8 35.5c-1.4 18.1-5.7 34.7-11.3 49.4c17-7.9 31.1-16.7 39.4-22.7zM21.2 431.9c1.8-2.7 3.5-5.4 5.1-8.1c10-16.6 19.5-38.4 21.4-62.9C17.7 326.8 0 285.1 0 240C0 125.1 114.6 32 256 32s256 93.1 256 208s-114.6 208-256 208c-37.1 0-72.3-6.4-104.1-17.9c-11.9 8.7-31.3 20.6-54.3 30.6c-15.1 6.6-32.3 12.6-50.1 16.1c-.8 .2-1.6 .3-2.4 .5c-4.4 .8-8.7 1.5-13.2 1.9c-.2 0-.5 .1-.7 .1c-5.1 .5-10.2 .8-15.3 .8c-6.5 0-12.3-3.9-14.8-9.9c-2.5-6-1.1-12.8 3.4-17.4c4.1-4.2 7.8-8.7 11.3-13.5c1.7-2.3 3.3-4.6 4.8-6.9c.1-.2 .2-.3 .3-.5z"/>
            </svg>
          </div>

          <p className="text-gray-500 text-center">
              {stage.get("name") == 'send' ?
               "Please send a message to your new partner about the wildlife population!" :
               "You haven't received any messages this round yet..."}
          </p>
        </div>
    </div>);
    }

    return (
        <div className="h-full w-full items-center overflow-auto pl-2 pr-4 pb-2" ref={scroller}>
            {msgsFiltered.map((msg, i) => (
                <Message 
                    key={msg.id} 
                    index={i} 
                    player={player} 
                    scope={scope} 
                    attribute={msg} 
                />
            ))}
        </div>
    );
}

//*
// MessageComp is the component showing an individual message. 



function MessageComp(props) {
    let {player, scope, attribute, index} = props;
    const msg = attribute.value;
    const ts = attribute.createdAt;



//likely redundant as senders avatar is set on new message
    let avatar = msg.sender.avatar;
    if (!avatar) {
        avatar = `https://api.dicebear.com/9.x/personas/svg?seed=${msg.sender.id}`;
    }
console.log('Avatar URL:', avatar);
    let item = scope.get("chat")[index];

    return (
        <div className="flex items-start my-2 shadow p-8">
            <div className="flex-shrink-0">
                <Avatar
            src={avatar}
            className="inline-block h-9 w-9 rounded-full"
        />
            </div>
            <div className="ml-3 text-sm">
                <p>
                    <span className="font-semibold text-gray-900 group-hover:text-gray-800">
                        {('neighbor')}
                    </span>
                    <span className="pl-2 text-gray-400">{ts && relTime(ts)}</span>
                </p>
                <p className="text-gray-900 group-hover:text-gray-800">{msg.text}</p>
            </div>
        </div>
    );
}



//*
// relTime is a function that formats the time since the given post (e.g. 2 min ago)
//*
function relTime(date) {
    const difference = (new Date().getTime() - date.getTime()) / 1000;
    if (difference < 60) {
        return `now`;
    }
    else if (difference < 3600) {
        return `${Math.floor(difference / 60)}m`;
    }
    else if (difference < 86400) {
        return `${Math.floor(difference / 3600)}h`;
    }
    else if (difference < 2620800) {
        return `${Math.floor(difference / 86400)} days ago`;
    }
    else if (difference < 31449600) {
        return `${Math.floor(difference / 2620800)} months ago`;
    }
    else {
        return `${Math.floor(difference / 31449600)} years ago`;
    }
}
