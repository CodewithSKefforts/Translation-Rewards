// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TranslationRewards {
    struct Translator {
        address translatorAddress;
        string name;
        string language;
        uint totalEarnings;
    }

    struct TranslationTask {
        uint taskId;
        string material;
        string targetLanguage;
        uint reward; // in wei
        address assignedTranslator;
        bool isCompleted;
    }

    mapping(address => Translator) public translators;
    mapping(uint => TranslationTask) public tasks;
    uint public nextTaskId;

    event TranslatorRegistered(address indexed translatorAddress, string name, string language);
    event TaskCreated(uint indexed taskId, string material, string targetLanguage, uint reward);
    event TaskAssigned(uint indexed taskId, address indexed translator);
    event TaskCompleted(uint indexed taskId, address indexed translator, uint reward);

    modifier onlyRegisteredTranslator() {
        require(bytes(translators[msg.sender].name).length > 0, "You are not a registered translator.");
        _;
    }

    function registerTranslator(string memory _name, string memory _language) external {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(bytes(_language).length > 0, "Language cannot be empty.");
        require(translators[msg.sender].translatorAddress == address(0), "Already registered as a translator.");

        translators[msg.sender] = Translator({
            translatorAddress: msg.sender,
            name: _name,
            language: _language,
            totalEarnings: 0
        });

        emit TranslatorRegistered(msg.sender, _name, _language);
    }

    function createTask(string memory _material, string memory _targetLanguage, uint _reward) external payable {
        require(bytes(_material).length > 0, "Material cannot be empty.");
        require(bytes(_targetLanguage).length > 0, "Target language cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(msg.value == _reward, "Reward amount must match the sent value.");
        require(nextTaskId + 1 > nextTaskId, "Task ID overflow detected.");

        tasks[nextTaskId] = TranslationTask({
            taskId: nextTaskId,
            material: _material,
            targetLanguage: _targetLanguage,
            reward: _reward,
            assignedTranslator: address(0),
            isCompleted: false
        });

        emit TaskCreated(nextTaskId, _material, _targetLanguage, _reward);
        nextTaskId++;
    }

    function assignTask(uint _taskId) external onlyRegisteredTranslator {
        TranslationTask storage task = tasks[_taskId];
        require(task.assignedTranslator == address(0), "Task is already assigned.");
        require(!task.isCompleted, "Task is already completed.");

        task.assignedTranslator = msg.sender;

        emit TaskAssigned(_taskId, msg.sender);
    }

    function completeTask(uint _taskId) external {
        TranslationTask storage task = tasks[_taskId];
        require(task.assignedTranslator == msg.sender, "You are not assigned to this task.");
        require(!task.isCompleted, "Task is already completed.");

        task.isCompleted = true;
        translators[msg.sender].totalEarnings += task.reward;

        (bool success, ) = msg.sender.call{value: task.reward}("");
        require(success, "Transfer failed.");

        emit TaskCompleted(_taskId, msg.sender, task.reward);
    }

    receive() external payable {
        // Allow contract to accept additional funds for task rewards
    }
}
