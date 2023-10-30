class Sequence:

    sequence: tuple
    instruction_index: int
    storage_value: int
    stack_position: int
    displacement: int

    def __init__(self, sequence, stack_position) -> None:
        self.instruction_index = 0
        self.storage_value = None
        self.sequence = sequence
        self.stack_position = stack_position
        self.displacement = 0
    
    def is_in_sequence(self, instruction: str, stack):
        if instruction.startswith(self.sequence[self.instruction_index]):
            if self.instruction_index == 0:
                self.displacement = stack[len(stack) -1]
            if self.storage_value is None and self.instruction_index == 1:
                stack_value = stack[len(stack) - self.stack_position]
                if isinstance(stack_value, dict):
                    value_list = []
                    for displacement in self.displacement:
                        value_list += list(stack_value[str(displacement)])
                    
                    self.storage_value = value_list
                else:
                    self.storage_value = list(stack_value)
            self.instruction_index = (self.instruction_index + 1)%len(self.sequence)
            return True

        
        self.instruction_index = 0
        self.storage_value = None
        return False

    def get_storage_value(self):
        return self.storage_value

    def __repr__(self) -> str:
        return f'Index: {self.instruction_index}, Value: {self.storage_value}'
        