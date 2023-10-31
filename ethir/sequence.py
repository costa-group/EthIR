class Sequence:

    sequence: tuple
    instruction_index: int
    storage_value: set
    stack_position: int
    displacement: set

    def __init__(self, sequence: tuple, stack_position: int) -> None:
        self.instruction_index = 0
        self.storage_value = None
        self.sequence = sequence
        self.stack_position = stack_position
        self.displacement = 0
    
    def register_instruction(self, instruction: str, stack: dict):
        if instruction.startswith(self.sequence[self.instruction_index]):

            # displacement in case of sload
            if self.instruction_index == 0:
                self.displacement = stack[len(stack) -1]
            
            # stack direction for sstore and sload
            if self.storage_value is None and self.instruction_index == 1:
                stack_value = stack[len(stack) - self.stack_position]

                # load the correct values from storage
                if isinstance(stack_value, dict):
                    values = set()
                    for displacement in self.displacement:
                        values = values.union(stack_value[str(displacement)])
                    
                    self.storage_value = values
                else:
                    self.storage_value = stack_value

            self.instruction_index = (self.instruction_index + 1)%len(self.sequence)

        
        self.instruction_index = 0
        self.storage_value = None

    def get_storage_value(self) -> set:
        return self.storage_value

    def __repr__(self) -> str:
        return f'Index: {self.instruction_index}, Value: {self.storage_value}'
        